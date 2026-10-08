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
