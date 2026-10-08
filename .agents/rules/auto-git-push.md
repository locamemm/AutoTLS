# Quy Tắc Tự Động Git Commit & Push (Auto Git Push Rule)

## 1. Yêu Cầu Bắt Buộc
- Mỗi khi hoàn thành bất kỳ tác vụ chỉnh sửa mã nguồn, thêm tính năng mới, sửa lỗi (bugfix), cải tiến UI/UX hoặc tối ưu hóa hiệu năng:
  - **BẮT BUỘC** tự động stage và commit các thay đổi với thông điệp rõ ràng, chuẩn conventional commits (`feat:`, `fix:`, `refactor:`, `perf:`, `chore:`...).
  - **BẮT BUỘC** tự động thực thi lệnh đẩy lên remote (`git push origin main`) ngay trong phiên làm việc.
  - **TUYỆT ĐỐI KHÔNG** chỉ dừng lại ở việc nhắc nhở người dùng "bạn hãy tự chạy lệnh git push origin main". Agent PHẢI chủ động chạy lệnh commit & push.

## 2. Quy Trình Thực Hiện Tự Động
1. `git add -A`
2. `git commit -m "<mô tả thay đổi rõ ràng>"`
3. `git push origin main`
4. Nếu remote có commit mới, tự động chạy `git pull --rebase origin main` rồi push lại.
