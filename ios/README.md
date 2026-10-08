# AutoTLS iOS - Ứng Dụng Gọi Tự Động Cho iOS (SwiftUI)

Phiên bản iOS của hệ thống **Auto Telesale Mobile**, được phát triển 100% bằng **SwiftUI** và **CallKit**, tương thích đầy đủ định dạng dữ liệu và tính năng với phiên bản Android.

---

## 🌟 Tính Năng Nổi Bật

1. **Giao diện Dark Theme hiện đại:**
   - Thống kê nhanh: Tổng số, Đã gọi, Chờ gọi.
   - Trạng thái rõ ràng, hỗ trợ tìm kiếm nhanh theo số điện thoại hoặc nội dung ghi chú.
   - Lọc nhanh theo trạng thái (Tất cả, Chờ gọi, Đang gọi..., Đã gọi).

2. **Quản lý danh sách liên hệ linh hoạt:**
   - **Tải file:** Mở file text (`.txt`) từ iCloud Drive, Bộ nhớ máy (Tệp/Files).
   - **Xuất file:** Chia sẻ file `.txt` đã cập nhật trạng thái/ghi chú qua AirDrop, Zalo, Drive, Tệp,...
   - Định dạng chuẩn: `0912345678|Ghi chú|#2563EB|Đã gọi` (hoàn toàn tương thích 1-1 với Android).
   - Tự động lưu tiến độ vào bộ nhớ ứng dụng (`saved_contacts_marks.txt`).

3. **Chiến dịch gọi điện tự động & Thông minh:**
   - **Bắt đầu:** Chạy lần lượt danh sách từ đầu hoặc từ liên hệ đang chờ gọi.
   - **Số tiếp theo:** Tự động chuyển hàng, đánh dấu trạng thái "Đã gọi", cuộn màn hình tới hàng tương ứng và quay số.
   - **Dừng:** Dừng chiến dịch bất kỳ lúc nào.
   - **Gọi từ số bất kỳ:** Nhấn vào liên hệ bất kỳ trong danh sách để bắt đầu chiến dịch từ số đó.

4. **Tích hợp CallKit (Theo dõi cuộc gọi):**
   - Sử dụng `CXCallObserver` để tự động nhận diện thời điểm cuộc gọi kết thúc.
   - Khi cuộc gọi kết thúc, ứng dụng tự động cập nhật trạng thái "Đã gọi", lưu lại file và bật sẵn nút **"Số tiếp theo"**.

5. **Mark Ghi Chú & Mẫu Nhanh (Templates):**
   - Đánh dấu màu sắc nổi bật với 7 bảng màu (Xám, Đỏ, Xanh dương, Cam, Tím, Xanh lá, Hồng).
   - Lưu trữ danh sách mẫu ghi chú nhanh (VD: *Khách hẹn gọi lại*, *Không nghe máy*, *Khách chốt đơn*, *Sai số*).
   - 1 chạm để áp dụng cả nội dung lẫn màu sắc.

6. **Tra cứu Zalo siêu tốc:**
   - Mở trực tiếp `zalo.me/<số_điện_thoại>` để kiểm tra thông tin đối tác/khách hàng.

---

## 🚀 Cách Build IPA Trên GitHub Actions

Kho lưu trữ đã được cấu hình sẵn GitHub Actions workflow tại:
[`.github/workflows/build-ipa.yml`](../.github/workflows/build-ipa.yml)

### Cách 1: Tự động khi Push code
Mỗi khi bạn commit và `git push` lên nhánh `main`, GitHub Actions sẽ tự động khởi động máy ảo macOS và build file `.ipa`.

### Cách 2: Chạy thủ công trên giao diện GitHub
1. Mở trang repo GitHub của bạn: [https://github.com/locamemm/AutoTLS](https://github.com/locamemm/AutoTLS)
2. Chuyển sang tab **Actions**.
3. Chọn workflow **Build iOS IPA** ở cột bên trái.
4. Nhấn **Run workflow** -> Chọn nhánh `main` -> Nhấn nút xanh **Run workflow**.
5. Đợi ~2-3 phút để quy trình hoàn tất.
6. Khi có dấu tích xanh (Success), nhấn vào job vừa chạy:
   - Kéo xuống mục **Artifacts**.
   - Tải file **`AutoTLS-iOS-IPA.zip`** về máy.
   - Giải nén file zip sẽ được file **`AutoTLS.ipa`**.

---

## 📲 Cách Cài Đặt File IPA Lên iPhone / iPad

Bạn có thể cài đặt file `.ipa` thông qua các công cụ phổ biến sau:

1. **TrollStore** (Dành cho iOS 14.0 - 17.0 tuỳ dòng máy):
   - Mở file `.ipa` trực tiếp bằng TrollStore để cài vĩnh viễn không cần ký chứng chỉ.
2. **Sideloadly / AltStore** (Sử dụng Apple ID miễn phí):
   - Kết nối iPhone với máy tính qua cáp.
   - Kéo file `AutoTLS.ipa` vào Sideloadly hoặc AltStore và nhập Apple ID để cài lên máy (hạn 7 ngày tự gia hạn).
3. **Esign / Scarlet / GBox / Scarlet Web / Feather**:
   - Nhập file `.ipa` vào và ký chứng chỉ doanh nghiệp (Enterprise Cert) hoặc chứng chỉ cá nhân (UDID P12).
