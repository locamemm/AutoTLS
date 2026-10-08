package com.example.autotelesale

data class Contact(
    val id: Int,
    val phoneNumber: String,
    var status: String = "Chờ gọi",
    var note: String = "",
    var noteColor: String = "#6B7280",
    var isCurrent: Boolean = false // Dùng để làm nổi bật hàng đang gọi
)