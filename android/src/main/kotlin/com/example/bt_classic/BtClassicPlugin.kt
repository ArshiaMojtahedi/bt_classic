package com.example.bt_classic

import android.Manifest
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothServerSocket
import android.bluetooth.BluetoothSocket
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.util.Base64
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.util.*

/** BtClassicPlugin */
class BtClassicPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel

  private val REQUEST_PERMISSIONS = 1001
  private val REQUEST_ENABLE_BT = 1002
  private val REQUEST_DISCOVERABLE = 1003
  
  private var bluetoothAdapter: BluetoothAdapter? = null
  private var bluetoothServerSocket: BluetoothServerSocket? = null
  private var bluetoothSocket: BluetoothSocket? = null
  private var activity: Activity? = null
  private var isServerRunning = false
  private var discoveredDevices = mutableListOf<Map<String, String>>()
  
  private val MY_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
  private val SERVICE_NAME = "BtClassicService"

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "bt_classic")
    channel.setMethodCallHandler(this)
    bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      // Common methods
      "requestPermissions" -> requestPermissions(result)
      "isBluetoothEnabled" -> result.success(bluetoothAdapter?.isEnabled ?: false)
      "sendMessage" -> {
        val message = call.argument<String>("message")
        if (message != null) {
          sendMessage(message, result)
        } else {
          result.error("MISSING_PARAM", "Message is required", null)
        }
      }
      "sendFile" -> {
        val fileData = call.argument<ByteArray>("fileData")
        val fileName = call.argument<String>("fileName")
        if (fileData != null && fileName != null) {
          sendFile(fileData, fileName, result)
        } else {
          result.error("MISSING_PARAM", "File data and filename are required", null)
        }
      }
      "disconnect" -> disconnect(result)
      "isConnected" -> result.success(bluetoothSocket?.isConnected ?: false)
      
      // Client methods
      "startDiscovery" -> startDiscovery(result)
      "stopDiscovery" -> stopDiscovery(result)
      "getPairedDevices" -> getPairedDevices(result)
      "connectToDevice" -> {
        val address = call.argument<String>("address")
        if (address != null) {
          connectToDevice(address, result)
        } else {
          result.error("MISSING_PARAM", "Device address is required", null)
        }
      }
      
      // Host methods
      "makeDiscoverable" -> makeDiscoverable(result)
      "startServer" -> startServer(result)
      "stopServer" -> stopServer(result)
      "isServerRunning" -> result.success(isServerRunning)
      "getDeviceName" -> result.success(bluetoothAdapter?.name ?: "Unknown Device")
      
      else -> result.notImplemented()
    }
  }

  private fun requestPermissions(result: Result) {
    val activity = this.activity ?: return result.error("NO_ACTIVITY", "Activity not available", null)
    
    val permissions = mutableListOf<String>()
    
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      permissions.addAll(listOf(
        Manifest.permission.BLUETOOTH_ADVERTISE,
        Manifest.permission.BLUETOOTH_CONNECT,
        Manifest.permission.BLUETOOTH_SCAN
      ))
    } else {
      permissions.addAll(listOf(
        Manifest.permission.BLUETOOTH,
        Manifest.permission.BLUETOOTH_ADMIN
      ))
    }
    
    permissions.addAll(listOf(
      Manifest.permission.ACCESS_FINE_LOCATION,
      Manifest.permission.ACCESS_COARSE_LOCATION
    ))
    
    val missingPermissions = permissions.filter {
      ContextCompat.checkSelfPermission(activity, it) != PackageManager.PERMISSION_GRANTED
    }
    
    if (missingPermissions.isNotEmpty()) {
      ActivityCompat.requestPermissions(activity, missingPermissions.toTypedArray(), REQUEST_PERMISSIONS)
      result.success(false) // Permissions requested but not yet granted
    } else {
      result.success(true)
    }
  }

  private fun hasBluetoothPermissions(): Boolean {
    val activity = this.activity ?: return false
    
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      ContextCompat.checkSelfPermission(activity, Manifest.permission.BLUETOOTH_ADVERTISE) == PackageManager.PERMISSION_GRANTED &&
      ContextCompat.checkSelfPermission(activity, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED &&
      ContextCompat.checkSelfPermission(activity, Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED
    } else {
      ContextCompat.checkSelfPermission(activity, Manifest.permission.BLUETOOTH) == PackageManager.PERMISSION_GRANTED &&
      ContextCompat.checkSelfPermission(activity, Manifest.permission.BLUETOOTH_ADMIN) == PackageManager.PERMISSION_GRANTED
    }
  }

  // Client methods
  private fun startDiscovery(result: Result) {
    if (!hasBluetoothPermissions()) {
      result.error("NO_PERMISSION", "Bluetooth permissions not granted", null)
      return
    }
    
    val activity = this.activity ?: return result.error("NO_ACTIVITY", "Activity not available", null)
    
    discoveredDevices.clear()
    if (bluetoothAdapter?.isDiscovering == true) {
      bluetoothAdapter?.cancelDiscovery()
    }
    
    val filter = IntentFilter().apply {
      addAction(BluetoothDevice.ACTION_FOUND)
      addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)
    }
    activity.registerReceiver(discoveryReceiver, filter)
    
    val started = bluetoothAdapter?.startDiscovery() ?: false
    result.success(started)
  }

  private val discoveryReceiver = object : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
      when (intent.action) {
        BluetoothDevice.ACTION_FOUND -> {
          val device: BluetoothDevice? = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
          device?.let {
            if (hasBluetoothPermissions()) {
              val deviceInfo = mapOf(
                "name" to (it.name ?: "Unknown Device"),
                "address" to it.address
              )
              discoveredDevices.add(deviceInfo)
              channel.invokeMethod("onDeviceFound", deviceInfo)
            }
          }
        }
        BluetoothAdapter.ACTION_DISCOVERY_FINISHED -> {
          channel.invokeMethod("onDiscoveryFinished", null)
        }
      }
    }
  }

  private fun stopDiscovery(result: Result) {
    if (!hasBluetoothPermissions()) {
      result.error("NO_PERMISSION", "Bluetooth permissions not granted", null)
      return
    }
    
    val stopped = bluetoothAdapter?.cancelDiscovery() ?: false
    result.success(stopped)
  }

  private fun getPairedDevices(result: Result) {
    if (!hasBluetoothPermissions()) {
      result.error("NO_PERMISSION", "Bluetooth permissions not granted", null)
      return
    }
    
    val pairedDevices = bluetoothAdapter?.bondedDevices?.map { device ->
      mapOf(
        "name" to (device.name ?: "Unknown Device"),
        "address" to device.address
      )
    } ?: emptyList()
    
    result.success(pairedDevices)
  }

  private fun connectToDevice(address: String, result: Result) {
    if (!hasBluetoothPermissions()) {
      result.error("NO_PERMISSION", "Bluetooth permissions not granted", null)
      return
    }
    
    Thread {
      try {
        bluetoothAdapter?.cancelDiscovery()
        
        val device = bluetoothAdapter?.getRemoteDevice(address)
        bluetoothSocket = device?.createRfcommSocketToServiceRecord(MY_UUID)
        
        try {
          bluetoothSocket?.connect()
        } catch (e: IOException) {
          try {
            val fallbackMethod = device?.javaClass?.getMethod("createRfcommSocket", Int::class.javaPrimitiveType)
            bluetoothSocket = fallbackMethod?.invoke(device, 1) as BluetoothSocket
            bluetoothSocket?.connect()
          } catch (e2: Exception) {
            Log.e("BtClassic", "Fallback socket also failed: ${e2.message}", e2)
            throw e
          }
        }
        
        startListening()
        
        activity?.runOnUiThread {
          result.success(true)
          channel.invokeMethod("onConnected", mapOf("address" to address))
        }
        
      } catch (e: Exception) {
        activity?.runOnUiThread {
          result.error("CONNECTION_FAILED", e.message, null)
        }
      }
    }.start()
  }

  // Host methods
  private fun makeDiscoverable(result: Result) {
    if (!hasBluetoothPermissions()) {
      result.error("NO_PERMISSION", "Bluetooth permissions not granted", null)
      return
    }
    
    val activity = this.activity ?: return result.error("NO_ACTIVITY", "Activity not available", null)
    
    val discoverableIntent = Intent(BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE).apply {
      putExtra(BluetoothAdapter.EXTRA_DISCOVERABLE_DURATION, 300)
    }
    activity.startActivityForResult(discoverableIntent, REQUEST_DISCOVERABLE)
    result.success(true)
  }

  private fun startServer(result: Result) {
    if (!hasBluetoothPermissions()) {
      result.error("NO_PERMISSION", "Bluetooth permissions not granted", null)
      return
    }
    
    if (isServerRunning) {
      result.success(true)
      return
    }
    
    Thread {
      try {
        bluetoothServerSocket?.close()
        bluetoothSocket?.close()
        bluetoothServerSocket = null
        bluetoothSocket = null
        
        bluetoothServerSocket = bluetoothAdapter?.listenUsingRfcommWithServiceRecord(SERVICE_NAME, MY_UUID)
        isServerRunning = true
        
        activity?.runOnUiThread {
          result.success(true)
          channel.invokeMethod("onServerStarted", null)
        }
        
        waitForConnection()
        
      } catch (e: IOException) {
        Log.e("BtClassic", "Server socket failed", e)
        isServerRunning = false
        bluetoothServerSocket = null
        activity?.runOnUiThread {
          result.error("SERVER_FAILED", e.message, null)
        }
      }
    }.start()
  }

  private fun waitForConnection() {
    try {
      bluetoothSocket = bluetoothServerSocket?.accept()
      
      val socket = bluetoothSocket
      if (socket != null) {
        activity?.runOnUiThread {
          val clientDevice = socket.remoteDevice
          if (hasBluetoothPermissions() && clientDevice != null) {
            val deviceInfo = mapOf(
              "name" to (clientDevice.name ?: "Unknown Device"),
              "address" to (clientDevice.address ?: "Unknown Address")
            )
            channel.invokeMethod("onClientConnected", mapOf("address" to clientDevice.address))
          }
        }
        
        startListening()
      }
      
    } catch (e: IOException) {
      Log.e("BtClassic", "Accept failed: ${e.message}", e)
      isServerRunning = false
      activity?.runOnUiThread {
        channel.invokeMethod("onError", mapOf("error" to e.message))
      }
    }
  }

  private fun stopServer(result: Result) {
    try {
      isServerRunning = false
      bluetoothServerSocket?.close()
      bluetoothSocket?.close()
      bluetoothServerSocket = null
      bluetoothSocket = null
      
      result.success(true)
      channel.invokeMethod("onServerStopped", null)
    } catch (e: IOException) {
      result.error("STOP_FAILED", e.message, null)
    }
  }

  // Common methods
  private fun sendMessage(message: String, result: Result) {
    Thread {
      try {
        val outputStream: OutputStream? = bluetoothSocket?.outputStream
        outputStream?.write((message + "\n").toByteArray())
        activity?.runOnUiThread {
          result.success(true)
        }
      } catch (e: IOException) {
        activity?.runOnUiThread {
          result.error("SEND_FAILED", e.message, null)
        }
      }
    }.start()
  }

  private fun sendFile(fileData: ByteArray, fileName: String, result: Result) {
    Thread {
      try {
        val base64Data = Base64.encodeToString(fileData, Base64.NO_WRAP)
        val message = "FILE:$fileName:$base64Data\n"
        
        val outputStream: OutputStream? = bluetoothSocket?.outputStream
        outputStream?.write(message.toByteArray())
        
        activity?.runOnUiThread {
          result.success(true)
        }
      } catch (e: IOException) {
        activity?.runOnUiThread {
          result.error("SEND_FAILED", e.message, null)
        }
      }
    }.start()
  }

  private fun startListening() {
    Thread {
      val inputStream: InputStream? = bluetoothSocket?.inputStream
      val buffer = ByteArray(1024)
      val messageBuffer = ByteArrayOutputStream()
      
      while (bluetoothSocket?.isConnected == true) {
        try {
          val bytes = inputStream?.read(buffer)
          if (bytes != null && bytes > 0) {
            messageBuffer.write(buffer, 0, bytes)
            
            val messageData = messageBuffer.toString()
            if (messageData.contains('\n') || messageData.length > 1000000) {
              val message = messageData.replace("\n", "")
              messageBuffer.reset()
              
              activity?.runOnUiThread {
                if (message.startsWith("FILE:")) {
                  try {
                    val parts = message.split(":", limit = 3)
                    if (parts.size == 3) {
                      val fileName = parts[1]
                      val base64Data = parts[2]
                      val fileData = Base64.decode(base64Data, Base64.NO_WRAP)
                      
                      channel.invokeMethod("onFileReceived", mapOf(
                        "fileName" to fileName,
                        "fileData" to fileData
                      ))
                    } else {
                      Log.e("BtClassic", "Invalid file message format: expected 3 parts, got ${parts.size}")
                      channel.invokeMethod("onMessageReceived", mapOf("message" to message))
                    }
                  } catch (e: Exception) {
                    Log.e("BtClassic", "Error processing file message: ${e.message}", e)
                    channel.invokeMethod("onMessageReceived", mapOf("message" to message))
                  }
                } else {
                  channel.invokeMethod("onMessageReceived", mapOf("message" to message))
                }
              }
            }
          } else {
            break
          }
        } catch (e: IOException) {
          Log.e("BtClassic", "Error reading from socket", e)
          break
        }
      }
      
      activity?.runOnUiThread {
        if (isServerRunning) {
          channel.invokeMethod("onClientDisconnected", null)
          restartServerSocket()
        } else {
          channel.invokeMethod("onDisconnected", null)
        }
      }
      
    }.start()
  }

  private fun restartServerSocket() {
    if (isServerRunning) {
      Thread {
        try {
          bluetoothSocket?.close()
          bluetoothSocket = null
          
          bluetoothServerSocket = bluetoothAdapter?.listenUsingRfcommWithServiceRecord(SERVICE_NAME, MY_UUID)
          waitForConnection()
        } catch (e: IOException) {
          Log.e("BtClassic", "Failed to restart server socket", e)
          isServerRunning = false
          activity?.runOnUiThread {
            channel.invokeMethod("onServerStopped", null)
          }
        }
      }.start()
    }
  }

  private fun disconnect(result: Result) {
    try {
      bluetoothSocket?.close()
      bluetoothSocket = null
      result.success(true)
      
      if (isServerRunning) {
        restartServerSocket()
        channel.invokeMethod("onClientDisconnected", null)
      } else {
        channel.invokeMethod("onDisconnected", null)
      }
      
    } catch (e: IOException) {
      result.error("DISCONNECT_FAILED", e.message, null)
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    cleanup()
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
    cleanup()
  }

  private fun cleanup() {
    try {
      isServerRunning = false
      bluetoothServerSocket?.close()
      bluetoothSocket?.close()
      activity?.unregisterReceiver(discoveryReceiver)
    } catch (e: Exception) {
      Log.e("BtClassic", "Error in cleanup", e)
    }
  }
}
