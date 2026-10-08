# Quy Tắc Phạm Vi: Chỉ Phát Triển Bản iOS (iOS Only Scope)

## 1. Yêu Cầu Bắt Buộc
- Kể từ thời điểm này, toàn bộ mọi yêu cầu chỉnh sửa, cập nhật tính năng, cải tiến giao diện, sửa lỗi hoặc tối ưu hiệu năng:
  - **CHỈ ĐƯỢC PHÉP ÁP DỤNG CHO DỰ ÁN IOS** (tập trung tại thư mục `ios/`).
  - **TUYỆT ĐỐI KHÔNG** tự ý chỉnh sửa mã nguồn của phiên bản Android (`app/`) trừ khi người dùng chỉ định rõ ràng.

## 2. Tiêu Chuẩn Nền Tảng iOS
- Sử dụng **SwiftUI**, **CallKit**, và **UniformTypeIdentifiers**.
- Giữ giao diện Dark Mode chuẩn thẩm mỹ iOS, mượt mà và trực quan.
- Đảm bảo CI/CD GitHub Actions (`.github/workflows/build-ipa.yml`) luôn build ra file `.ipa` thành công.
