package com.example.autotelesale

import android.content.res.Configuration
import android.graphics.Color
import android.os.SystemClock
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView

class ContactAdapter(
    private val contacts: List<Contact>,
    private val listener: OnContactActionListener? = null
) : RecyclerView.Adapter<ContactAdapter.ContactViewHolder>() {

    interface OnContactActionListener {
        fun onContactAction(contact: Contact)
    }

    inner class ContactViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val index: TextView = itemView.findViewById(R.id.contact_index)
        val phone: TextView = itemView.findViewById(R.id.contact_phone)
        val status: TextView = itemView.findViewById(R.id.contact_status)
        val note: TextView = itemView.findViewById(R.id.contact_note)
        var lastTapTime: Long = 0L
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ContactViewHolder {
        val view = LayoutInflater.from(parent.context).inflate(R.layout.list_item_contact, parent, false)
        return ContactViewHolder(view)
    }

    override fun getItemCount(): Int = contacts.size

    override fun onBindViewHolder(holder: ContactViewHolder, position: Int) {
        val contact = contacts[position]
        holder.index.text = "${contact.id}."
        holder.phone.text = contact.phoneNumber
        holder.status.text = contact.status

        holder.itemView.setOnClickListener {
            val now = SystemClock.elapsedRealtime()
            if (now - holder.lastTapTime < 300) {
                listener?.onContactAction(contact)
            }
            holder.lastTapTime = now
        }

        holder.phone.setOnTouchListener { view, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    view.animate()
                        .scaleX(0.97f)
                        .scaleY(0.97f)
                        .translationY(2f)
                        .setDuration(70)
                        .start()
                    false
                }
                MotionEvent.ACTION_UP,
                MotionEvent.ACTION_CANCEL -> {
                    view.animate()
                        .scaleX(1f)
                        .scaleY(1f)
                        .translationY(0f)
                        .setDuration(70)
                        .start()
                    false
                }
                else -> false
            }
        }

        if (contact.note.isNotBlank()) {
            holder.note.text = "Ghi chú: ${contact.note}"
            holder.note.setTextColor(Color.parseColor(contact.noteColor))
            holder.note.visibility = View.VISIBLE
        } else {
            holder.note.visibility = View.GONE
        }

        val isDarkMode = holder.itemView.context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK == Configuration.UI_MODE_NIGHT_YES
        val primaryTextColor = if (isDarkMode) Color.WHITE else Color.BLACK
        val secondaryTextColor = if (isDarkMode) Color.LTGRAY else Color.GRAY

        holder.index.setTextColor(primaryTextColor)
        holder.phone.setTextColor(primaryTextColor)

        // Làm nổi bật mục đang được gọi ở mức nhẹ hơn
        if (contact.isCurrent) {
            holder.itemView.setBackgroundColor(if (isDarkMode) Color.parseColor("#2B3A4A") else Color.parseColor("#EAF4FF"))
        } else if (isDarkMode) {
            holder.itemView.setBackgroundColor(Color.parseColor("#1F2937"))
        } else {
            holder.itemView.setBackgroundResource(R.drawable.item_background)
        }

        // Thay đổi màu chữ trạng thái cho trực quan
        val statusColor = when (contact.status) {
            "Đang gọi..." -> if (isDarkMode) Color.parseColor("#7DD3FC") else Color.parseColor("#2563EB")
            "Đã gọi" -> if (isDarkMode) Color.parseColor("#86EFAC") else Color.parseColor("#2E7D32")
            else -> secondaryTextColor
        }
        holder.status.setTextColor(statusColor)
    }
}