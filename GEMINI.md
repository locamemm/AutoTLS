# Hướng Dẫn & Quy Tắc Dự Án (AutoTLS)

## 1. Quy Tắc Tự Động Git Commit & Push (Mandatory Auto Git Push)
- **Yêu cầu bắt buộc đối với AI Assistant (Agent):**
  - Mỗi khi hoàn thành bất kỳ tác vụ chỉnh sửa mã nguồn, thêm tính năng mới, sửa lỗi (bugfix), cập nhật giao diện hoặc cấu hình:
    - **BẮT BUỘC** tự động stage và commit các thay đổi với commit message rõ ràng, chuẩn Conventional Commits (`feat:`, `fix:`, `refactor:`, `chore:`, `docs:`...).
    - **BẮT BUỘC** tự động thực thi lệnh đẩy trực tiếp lên GitHub (`git push origin main`) ngay trong phiên làm việc.
    - **TUYỆT ĐỐI KHÔNG** chỉ dừng lại ở việc nhắc nhở người dùng "bạn hãy tự chạy lệnh git push". Agent PHẢI chủ động thực thi lệnh qua terminal.
    - Nếu remote có commit mới, tự động chạy `git pull --rebase origin main` rồi thực hiện push lại.

## 2. Tiêu Chuẩn Công Nghệ Dự Án
- **Android:** Kotlin, Jetpack Compose / XML Views, TelephonyManager.
- **iOS:** SwiftUI (iOS 15+), CallKit (`CXCallObserver`), DocumentPicker / ShareLink.
- **Định dạng dữ liệu liên hệ tương thích chéo 1-1:**
  `phoneNumber|note|noteColor|status`
- **CI/CD:** GitHub Actions tự động build file cài đặt `.ipa` cho iOS (`.github/workflows/build-ipa.yml`).

## 3. Phạm Vi Phát Triển (Scope Constraint) - CHỈ ÁP DỤNG CHO BẢN IOS
- **Quy tắc bắt buộc:**
  - Kể từ bây giờ, tất cả các yêu cầu chỉnh sửa, cập nhật tính năng, cải tiến giao diện, tối ưu hoá hoặc sửa lỗi **CHỈ ĐƯỢC PHÉP ÁP DỤNG CHO PHIÊN BẢN IOS** (nằm trong thư mục `ios/`).
  - **TUYỆT ĐỐI KHÔNG** can thiệp hay sửa đổi mã nguồn của phiên bản Android (`app/`) trừ khi người dùng có yêu cầu rõ ràng bằng lời nhắc riêng biệt.
  - Toàn bộ các tài nguyên, workflow GitHub Actions, cấu hình và tính năng mới đều tập trung tối ưu cho trải nghiệm người dùng trên iOS.

## 4. Tối Ưu Tốc Độ Thao Tác & Triệt Tiêu Thông Báo (Zero Interruptive Alerts)
- **Quy tắc bắt buộc:**
  - **TUYỆT ĐỐI KHÔNG** dùng các popup cảnh báo (`Alert`, `Dialog`, pop-up có nút `OK`) gây gián đoạn luồng làm việc telesale của người dùng.
  - Loại bỏ toàn bộ các popup thông báo hoàn thành, kết thúc cuộc gọi, đổi trạng thái, lưu ghi chú, tải file...
  - Mọi thông tin trạng thái chỉ cập nhật tinh tế vào nhãn trạng thái chính (`statusMessage`) hoặc các badge trên giao diện.
  - Ưu tiên cao nhất cho **tốc độ thao tác (Instant Action)**: Người dùng bấm là thực hiện ngay lập tức, không bắt người dùng phải bấm "OK" hay xác nhận phiền hà.
