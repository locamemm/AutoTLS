package com.example.autotelesale

import android.Manifest
import android.app.AlertDialog
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.telephony.PhoneStateListener
import android.telephony.TelephonyManager
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.graphics.drawable.GradientDrawable
import android.widget.Button
import android.widget.EditText
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.RadioButton
import android.widget.RadioGroup
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.app.AppCompatDelegate
import androidx.core.content.ContextCompat
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.nio.charset.StandardCharsets

@Suppress("DEPRECATION") // Sử dụng PhoneStateListener để tương thích rộng hơn
class MainActivity : AppCompatActivity(), ContactAdapter.OnContactActionListener {

    private companion object {
        const val DEFAULT_NOTE_COLOR = "#6B7280"
        const val MARKS_FILE_NAME = "saved_contacts_marks.txt"
    }

    // UI Elements
    private lateinit var loadFileButton: Button
    private lateinit var startButton: Button
    private lateinit var nextButton: Button
    private lateinit var stopButton: Button
    private lateinit var statusLabel: TextView
    private lateinit var contactsRecyclerView: RecyclerView

    // Data and State
    private val contactList = mutableListOf<Contact>()
    private lateinit var contactAdapter: ContactAdapter
    private var currentSourceUri: Uri? = null
    private var currentIndex = -1
    private var isCampaignRunning = false

    // Trình khởi chạy để xin quyền (cách hiện đại)
    private val requestPermissionsLauncher =
        registerForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { permissions ->
            val allGranted = permissions.entries.all { it.value }
            if (allGranted) {
                Toast.makeText(this, "Đã cấp đủ quyền!", Toast.LENGTH_SHORT).show()
                listenToCallState() // Bắt đầu lắng nghe trạng thái cuộc gọi sau khi có quyền
            } else {
                Toast.makeText(this, "Ứng dụng cần các quyền đã yêu cầu để hoạt động.", Toast.LENGTH_LONG).show()
            }
        }

    // Trình khởi chạy để chọn file (cách hiện đại)
    private val filePickerLauncher =
        registerForActivityResult(ActivityResultContracts.OpenDocument()) { uri: Uri? ->
            uri?.let {
                try {
                    val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                    contentResolver.takePersistableUriPermission(it, flags)
                } catch (e: SecurityException) {
                    e.printStackTrace()
                }
                loadContactsFromFile(it)
            }
        }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_YES)
        setContentView(R.layout.activity_main)

        bindViews()
        setupRecyclerView()
        setupClickListeners()
        updateButtonStates()

        checkAndRequestPermissions()
    }

    private fun bindViews() {
        loadFileButton = findViewById(R.id.loadFileButton)
        startButton = findViewById(R.id.startButton)
        nextButton = findViewById(R.id.nextButton)
        stopButton = findViewById(R.id.stopButton)
        statusLabel = findViewById(R.id.statusLabel)
        contactsRecyclerView = findViewById(R.id.contactsRecyclerView)
    }

    private fun setupRecyclerView() {
        contactAdapter = ContactAdapter(contactList, this)
        contactsRecyclerView.layoutManager = LinearLayoutManager(this)
        contactsRecyclerView.adapter = contactAdapter
    }

    private fun setupClickListeners() {
        loadFileButton.setOnClickListener {
            filePickerLauncher.launch(arrayOf("text/plain", "text/*"))
        }
        startButton.setOnClickListener { startCampaign() }
        nextButton.setOnClickListener { nextCall() }
        stopButton.setOnClickListener { stopCampaign() }
    }

    private fun checkAndRequestPermissions() {
        val permissionsToRequest = arrayOf(
            Manifest.permission.CALL_PHONE,
            Manifest.permission.READ_PHONE_STATE
            // READ_EXTERNAL_STORAGE không cần thiết với cách chọn file hiện đại
        )
        requestPermissionsLauncher.launch(permissionsToRequest)
    }

    private fun loadContactsFromFile(uri: Uri) {
        try {
            currentSourceUri = uri
            contentResolver.openInputStream(uri)?.use { inputStream ->
                BufferedReader(InputStreamReader(inputStream, StandardCharsets.UTF_8)).use { reader ->
                    contactList.clear()
                    var idCounter = 1
                    reader.forEachLine { line ->
                        parseContactLine(line, idCounter)?.let { contact ->
                            contactList.add(contact)
                            idCounter++
                        }
                    }
                }
            }
            contactAdapter.notifyDataSetChanged()
            statusLabel.text = "Đã tải ${contactList.size} số. Sẵn sàng bắt đầu."
            Toast.makeText(this, "Đã tải ${contactList.size} số điện thoại.", Toast.LENGTH_SHORT).show()
        } catch (e: Exception) {
            e.printStackTrace()
            Toast.makeText(this, "Lỗi khi đọc file: ${e.message}", Toast.LENGTH_LONG).show()
        }
    }

    private fun parseContactLine(line: String, id: Int): Contact? {
        val trimmed = line.trim()
        if (trimmed.isBlank()) return null

        return if (trimmed.contains("|")) {
            val parts = trimmed.split("|")
            val phoneNumber = parts.getOrNull(0)?.trim()?.filter { it.isDigit() }.orEmpty()
            if (phoneNumber.length < 9) return null

            val note = parts.getOrNull(1)?.replace("\\n", "\n")?.replace("\\|", "|") ?: ""
            val color = parts.getOrNull(2)?.takeIf { it.isNotBlank() } ?: DEFAULT_NOTE_COLOR
            val status = parts.getOrNull(3)?.takeIf { it.isNotBlank() } ?: "Chờ gọi"

            Contact(id = id, phoneNumber = phoneNumber, note = note, noteColor = color, status = status)
        } else {
            val phoneNumber = trimmed.filter { it.isDigit() }
            if (phoneNumber.length >= 9) {
                Contact(id = id, phoneNumber = phoneNumber)
            } else {
                null
            }
        }
    }

    private fun saveContactsToFile() {
        try {
            val writerContent = StringBuilder()
            contactList.forEach { contact ->
                val noteText = contact.note.replace("\n", "\\n").replace("|", "\\|")
                writerContent.append("${contact.phoneNumber}|${noteText}|${contact.noteColor}|${contact.status}\n")
            }

            if (currentSourceUri != null) {
                contentResolver.openOutputStream(currentSourceUri!!, "w")?.use { outputStream ->
                    OutputStreamWriter(outputStream, StandardCharsets.UTF_8).use { writer ->
                        writer.write(writerContent.toString())
                    }
                }
            } else {
                val file = File(filesDir, MARKS_FILE_NAME)
                file.outputStream().use { outputStream ->
                    OutputStreamWriter(outputStream, StandardCharsets.UTF_8).use { writer ->
                        writer.write(writerContent.toString())
                    }
                }
            }
            Toast.makeText(this, "Đã lưu thay đổi", Toast.LENGTH_SHORT).show()
        } catch (e: Exception) {
            e.printStackTrace()
            Toast.makeText(this, "Không lưu được: ${e.message}", Toast.LENGTH_LONG).show()
        }
    }

    private fun startCampaign() {
        if (contactList.isEmpty()) {
            Toast.makeText(this, "Vui lòng tải danh sách số điện thoại trước.", Toast.LENGTH_SHORT).show()
            return
        }
        isCampaignRunning = true
        currentIndex = 0
        statusLabel.text = "Chiến dịch đang chạy..."
        makeCallForCurrentIndex()
    }

    private fun nextCall() {
        if (!isCampaignRunning || currentIndex < 0) return

        currentIndex++
        if (currentIndex < contactList.size) {
            makeCallForCurrentIndex()
        } else {
            Toast.makeText(this, "Đã hoàn thành chiến dịch!", Toast.LENGTH_LONG).show()
            stopCampaign()
        }
    }

    private fun stopCampaign() {
        isCampaignRunning = false
        if (currentIndex >= 0 && currentIndex < contactList.size) {
            contactList[currentIndex].isCurrent = false
            contactAdapter.notifyItemChanged(currentIndex)
        }
        currentIndex = -1
        updateButtonStates()
        statusLabel.text = "Chiến dịch đã dừng. Sẵn sàng."
    }

    private fun makeCallForCurrentIndex() {
        if (currentIndex < 0 || currentIndex >= contactList.size) return

        // Bỏ highlight mục trước đó nếu có
        if (currentIndex > 0) {
            contactList[currentIndex - 1].isCurrent = false
        }

        val contact = contactList[currentIndex]
        contact.status = "Đã gọi"
        contact.isCurrent = true
        contactAdapter.notifyDataSetChanged()
        contactsRecyclerView.scrollToPosition(currentIndex)
        saveContactsToFile()

        updateButtonStates(isCallActive = false)
        makeCall(contact.phoneNumber)
    }

    private fun makeCall(phoneNumber: String) {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) == PackageManager.PERMISSION_GRANTED) {
            val intent = Intent(Intent.ACTION_CALL, Uri.parse("tel:$phoneNumber"))
            startActivity(intent)
        } else {
            Toast.makeText(this, "Quyền gọi điện chưa được cấp.", Toast.LENGTH_SHORT).show()
            checkAndRequestPermissions()
        }
    }

    private fun listenToCallState() {
        val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        val phoneStateListener = object : PhoneStateListener() {
            private var wasOffHook = false
            override fun onCallStateChanged(state: Int, phoneNumber: String?) {
                if (!isCampaignRunning) return

                when (state) {
                    TelephonyManager.CALL_STATE_OFFHOOK -> wasOffHook = true
                    TelephonyManager.CALL_STATE_IDLE -> {
                        if (wasOffHook) {
                            wasOffHook = false
                            runOnUiThread { handleCallEnded() }
                        }
                    }
                }
            }
        }
        telephonyManager.listen(phoneStateListener, PhoneStateListener.LISTEN_CALL_STATE)
    }

    private fun handleCallEnded() {
        Toast.makeText(applicationContext, "Cuộc gọi kết thúc. Nhấn 'Số tiếp theo'.", Toast.LENGTH_SHORT).show()
        if (currentIndex in 0 until contactList.size) {
            contactList[currentIndex].status = "Đã gọi"
            contactAdapter.notifyItemChanged(currentIndex)
            saveContactsToFile()
        }
        updateButtonStates(isCallActive = false)
    }

    private fun updateButtonStates(isCallActive: Boolean = false) {
        startButton.isEnabled = !isCampaignRunning
        loadFileButton.isEnabled = !isCampaignRunning
        stopButton.isEnabled = isCampaignRunning
        nextButton.isEnabled = isCampaignRunning && currentIndex >= 0 && currentIndex < contactList.size
    }

    override fun onContactAction(contact: Contact) {
        val menuItems = listOf(
            MenuItemData("Gọi lại số này", android.R.drawable.ic_menu_call, 0),
            MenuItemData("Gọi từ số này", android.R.drawable.ic_menu_send, 1),
            MenuItemData("Trạng thái", android.R.drawable.ic_menu_edit, 2),
            MenuItemData("Mark", android.R.drawable.ic_menu_agenda, 3),
            MenuItemData("Tra số trong Zalo", android.R.drawable.ic_menu_search, 4)
        )

        val dialogView = LayoutInflater.from(this).inflate(R.layout.dialog_contact_menu, null)
        val container = dialogView.findViewById<LinearLayout>(R.id.menuContainer)

        menuItems.forEach { item ->
            val row = LayoutInflater.from(this).inflate(R.layout.menu_item_row, container, false)
            val icon = row.findViewById<ImageView>(R.id.menuIcon)
            val label = row.findViewById<TextView>(R.id.menuLabel)
            icon.setImageResource(item.iconRes)
            label.text = item.label
            row.setOnClickListener {
                when (item.actionId) {
                    0 -> makeCall(contact.phoneNumber)
                    1 -> startCampaignFrom(contact)
                    2 -> showStatusDialog(contact)
                    3 -> showNoteDialog(contact)
                    4 -> openZalo(contact.phoneNumber)
                }
            }
            container.addView(row)
        }

        AlertDialog.Builder(this)
            .setTitle(contact.phoneNumber)
            .setView(dialogView)
            .show()
    }

    private fun showStatusDialog(contact: Contact) {
        val statusOptions = arrayOf("Chờ gọi", "Đang gọi...", "Đã gọi")
        AlertDialog.Builder(this)
            .setTitle("Trạng thái cho ${contact.phoneNumber}")
            .setItems(statusOptions) { _, which ->
                val selectedStatus = statusOptions[which]
                contact.status = selectedStatus
                val position = contactList.indexOf(contact)
                if (position >= 0) {
                    contactAdapter.notifyItemChanged(position)
                }
                saveContactsToFile()
                Toast.makeText(this, "Đã cập nhật trạng thái: $selectedStatus", Toast.LENGTH_SHORT).show()
            }
            .show()
    }

    private fun openZalo(phoneNumber: String) {
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://zalo.me/$phoneNumber"))
            startActivity(intent)
        } catch (e: Exception) {
            Toast.makeText(this, "Không thể mở Zalo: ${e.message}", Toast.LENGTH_SHORT).show()
        }
    }

    private fun getTemplates(): List<TemplateMark> {
        val prefs = getSharedPreferences("mark_templates", Context.MODE_PRIVATE)
        val json = prefs.getString("templates_json", null)
        if (json == null) {
            val oldNote = prefs.getString("template_note", null)
            if (oldNote != null) {
                val oldColor = prefs.getString("template_color", DEFAULT_NOTE_COLOR) ?: DEFAULT_NOTE_COLOR
                val singleList = listOf(TemplateMark(oldNote, oldColor))
                saveTemplates(singleList)
                return singleList
            }
            return emptyList()
        }

        val list = mutableListOf<TemplateMark>()
        try {
            val array = JSONArray(json)
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                list.add(TemplateMark(obj.getString("note"), obj.getString("color")))
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return list
    }

    private fun saveTemplates(templates: List<TemplateMark>) {
        val prefs = getSharedPreferences("mark_templates", Context.MODE_PRIVATE)
        val array = JSONArray()
        templates.forEach {
            val obj = JSONObject()
            obj.put("note", it.note)
            obj.put("color", it.color)
            array.put(obj)
        }
        prefs.edit().putString("templates_json", array.toString()).apply()
    }

    private fun showNoteDialog(contact: Contact) {
        val prefs = getSharedPreferences("mark_templates", Context.MODE_PRIVATE)

        val input = EditText(this).apply {
            setText("")
            hint = "Nhập ghi chú"
            setSingleLine(false)
            minLines = 3
        }

        var selectedColor = if (contact.note.isNotBlank()) contact.noteColor else DEFAULT_NOTE_COLOR
        val (colorPickerView, updateColorPicker) = createColorPicker(selectedColor) {
            selectedColor = it
        }

        val templateListContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(0, 8, 0, 8)
        }

        fun refreshTemplatesUI() {
            templateListContainer.removeAllViews()
            val currentTemplates = getTemplates()
            if (currentTemplates.isEmpty()) {
                templateListContainer.visibility = View.GONE
            } else {
                templateListContainer.visibility = View.VISIBLE
                currentTemplates.forEach { template ->
                    val templateRow = LinearLayout(this).apply {
                        orientation = LinearLayout.HORIZONTAL
                        gravity = Gravity.CENTER_VERTICAL
                        setPadding(0, 4, 0, 4)

                        addView(TextView(this@MainActivity).apply {
                            text = "📌 ${template.note.replace("\n", " ").take(40)}${if(template.note.length > 40) "..." else ""}"
                            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
                            setTextColor(android.graphics.Color.parseColor(template.color))
                            setOnClickListener {
                                input.setText(template.note)
                                selectedColor = template.color
                                updateColorPicker(template.color)
                                Toast.makeText(this@MainActivity, "Đã dùng mẫu", Toast.LENGTH_SHORT).show()
                            }
                        })

                        addView(TextView(this@MainActivity).apply {
                            text = "✕"
                            textSize = 18f
                            setPadding(20, 10, 20, 10)
                            setTextColor(android.graphics.Color.GRAY)
                            setOnClickListener {
                                val newList = getTemplates().filter { it != template }
                                saveTemplates(newList)
                                refreshTemplatesUI()
                            }
                        })
                    }
                    templateListContainer.addView(templateRow)
                }
            }
        }

        refreshTemplatesUI()

        val quickTemplateButton = TextView(this).apply {
            text = " + Thêm mẫu "
            textSize = 14f
            gravity = Gravity.CENTER
            setPadding(16, 8, 16, 8)
            setBackgroundResource(android.R.drawable.btn_default_small)
            setTextColor(ContextCompat.getColor(this@MainActivity, android.R.color.white))
            setOnClickListener {
                val templateInput = EditText(this@MainActivity).apply {
                    hint = "Nội dung Mark mẫu"
                    setSingleLine(false)
                    minLines = 3
                }
                
                var templateSelectedColor = DEFAULT_NOTE_COLOR
                val (tColorPicker, tUpdate) = createColorPicker(templateSelectedColor) {
                    templateSelectedColor = it
                }

                val templateContainer = LinearLayout(this@MainActivity).apply {
                    orientation = LinearLayout.VERTICAL
                    setPadding(24, 0, 24, 0)
                    addView(templateInput)
                    addView(TextView(this@MainActivity).apply {
                        text = "Chọn màu cho mẫu"
                        setPadding(0, 12, 0, 4)
                    })
                    addView(tColorPicker)
                }
                AlertDialog.Builder(this@MainActivity)
                    .setTitle("Tạo Mark mẫu mới")
                    .setView(templateContainer)
                    .setPositiveButton("Lưu") { _, _ ->
                        val newNote = templateInput.text.toString().trim()
                        if (newNote.isNotBlank()) {
                            val newList = getTemplates().toMutableList()
                            newList.add(TemplateMark(newNote, templateSelectedColor))
                            saveTemplates(newList)
                            refreshTemplatesUI()
                            
                            input.setText(newNote)
                            selectedColor = templateSelectedColor
                            updateColorPicker(templateSelectedColor)
                        }
                    }
                    .setNegativeButton("Huỷ", null)
                    .show()
            }
        }

        val topRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.END
            addView(quickTemplateButton)
        }

        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(24, 0, 24, 0)
            addView(topRow)
            addView(templateListContainer)
            addView(input)
            addView(TextView(this@MainActivity).apply {
                text = "Chọn màu ghi chú"
                setPadding(0, 12, 0, 4)
            })
            addView(colorPickerView)
        }

        AlertDialog.Builder(this)
            .setTitle("Mark cho ${contact.phoneNumber}")
            .setView(container)
            .setPositiveButton("Lưu") { _, _ ->
                contact.note = input.text.toString().trim()
                contact.noteColor = selectedColor
                val position = contactList.indexOf(contact)
                if (position >= 0) {
                    contactAdapter.notifyItemChanged(position)
                }
                saveContactsToFile()
            }
            .setNegativeButton("Huỷ", null)
            .show()
    }

    private fun createColorPicker(
        initialColor: String,
        onColorSelected: (String) -> Unit
    ): Pair<LinearLayout, (String) -> Unit> {
        val container = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(0, 8, 0, 8)
        }

        val colors = listOf(DEFAULT_NOTE_COLOR, "#DC2626", "#2563EB", "#D97706", "#7C3AED", "#10B981", "#EC4899")
        val views = mutableListOf<View>()

        val updater = { selectedColor: String ->
            views.forEach { view ->
                val colorStr = view.tag as String
                val isSelected = colorStr.equals(selectedColor, ignoreCase = true)
                val drawable = GradientDrawable().apply {
                    shape = GradientDrawable.OVAL
                    setColor(android.graphics.Color.parseColor(colorStr))
                    if (isSelected) {
                        setStroke(6, android.graphics.Color.WHITE)
                    } else {
                        setStroke(2, android.graphics.Color.TRANSPARENT)
                    }
                }
                view.background = drawable
            }
        }

        colors.forEach { color ->
            val size = (38 * resources.displayMetrics.density).toInt()
            val margin = (10 * resources.displayMetrics.density).toInt()
            val view = View(this).apply {
                layoutParams = LinearLayout.LayoutParams(size, size).apply {
                    setMargins(0, 0, margin, 0)
                }
                tag = color
                setOnClickListener {
                    onColorSelected(color)
                    updater(color)
                }
            }
            views.add(view)
            container.addView(view)
        }

        updater(initialColor)
        return container to updater
    }

    private fun startCampaignFrom(contact: Contact) {
        val index = contactList.indexOf(contact)
        if (index < 0) return

        currentIndex = index
        isCampaignRunning = true
        statusLabel.text = "Đang gọi từ số ${contact.phoneNumber}..."
        makeCallForCurrentIndex()
    }

    private data class MenuItemData(val label: String, val iconRes: Int, val actionId: Int)
    private data class TemplateMark(val note: String, val color: String)
}