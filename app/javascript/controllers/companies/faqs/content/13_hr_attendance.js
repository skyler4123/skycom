export default {
  key: "hr_attendance",
  icon: "schedule",
  title: {
    en: "HR: shifts & attendance",
    vi: "Nhân sự: ca làm & chấm công"
  },
  questions: [
    {
      slug: "shift-template-versus-scheduled-shift",
      question: {
        en: "What is a shift template vs a scheduled shift?",
        vi: "Mẫu ca và ca đã lên lịch khác nhau thế nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "A shift template is a reusable definition: a name, start and end time, grace period, and unpaid break. A scheduled shift applies that template to one employee on one work date, with expected start and end times and a status. Templates let you change the shape of a shift once; scheduled shifts are the actual roster the attendance engine compares against. Editing a template does not rewrite past attendance days.",
            vi: "Mẫu ca là định nghĩa dùng lại: tên, giờ bắt đầu và kết thúc, thời gian ân hạn và nghỉ không lương. Ca đã lên lịch áp mẫu đó cho một nhân viên vào một ngày làm việc, với giờ bắt đầu và kết thúc dự kiến cùng trạng thái. Mẫu giúp đổi hình dạng ca một lần; ca đã lên lịch là lịch thực tế mà bộ máy chấm công so sánh. Sửa mẫu không viết lại các ngày chấm công đã qua."
          }
        },
        {
          type: "links",
          items: [
            { label: { en: "Open Shift Templates", vi: "Mở Mẫu ca" }, path: "company_shift_templates_path" },
            { label: { en: "Open Shifts", vi: "Mở Ca làm" }, path: "company_scheduled_shifts_path" }
          ]
        }
      ]
    },
    {
      slug: "employee-check-in-out",
      question: {
        en: "How do employees check in and out?",
        vi: "Nhân viên chấm công vào và ra thế nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Employees check in from the mobile app's Home screen; the action creates a permanent attendance record with the time, GPS position, and device context. The check-out service exists in the platform, but the mobile screen currently exposes check-in only, so a missing check-out becomes a manager follow-up or an attendance request. Web dashboards show the resulting days and months; they are not the clock-in surface.",
            vi: "Nhân viên chấm công vào từ màn hình Home của ứng dụng di động; thao tác tạo một bản ghi chấm công cố định với thời gian, vị trí GPS và ngữ cảnh thiết bị. Dịch vụ chấm công ra đã có trong nền tảng, nhưng màn hình di động hiện chỉ mở chức năng vào, nên thiếu giờ ra sẽ do quản lý xử lý hoặc tạo yêu cầu chấm công. Bảng trên web hiển thị ngày và tháng kết quả; đó không phải nơi chấm công."
          }
        }
      ]
    },
    {
      slug: "check-in-gps-shift",
      question: {
        en: "Does check-in require GPS or a scheduled shift?",
        vi: "Chấm công có cần GPS hoặc ca đã lên lịch không?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "It depends on the branch's attendance configuration. When the geofence is enforced, a missing position fails with a location-required message, and a point outside the allowed radius fails with an outside-area message; a matching WiFi SSID can satisfy the same rule. Mobile check-in does not require a scheduled shift, so an employee without a roster row can still clock in. The web simulator uses stricter defaults and does require a shift.",
            vi: "Tùy cấu hình chấm công của chi nhánh. Khi hàng rào địa lý được bật, thiếu vị trí sẽ báo cần vị trí, và điểm ngoài bán kính cho phép sẽ báo ngoài khu vực; SSID WiFi khớp có thể thỏa cùng quy tắc. Chấm công di động không bắt buộc có ca đã lên lịch, nên nhân viên chưa có dòng lịch vẫn chấm được. Bộ mô phỏng trên web dùng mặc định chặt hơn và có yêu cầu ca."
          }
        }
      ]
    },
    {
      slug: "configure-geofence",
      question: {
        en: "What is a geofence, and how do I configure it?",
        vi: "Hàng rào địa lý là gì và làm sao cấu hình?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "A geofence is a latitude, longitude, and allowed radius attached to a branch's attendance configuration; a check-in must be inside it or match the configured WiFi network. Open Attendance Configs, choose the branch, and set the coordinates, radius, WiFi option, and resolution strategy. The config log keeps a history of changes, which matters when an employee disputes a rejected check-in. Without a config, the branch has no geofence to enforce.",
            vi: "Hàng rào địa lý là vĩ độ, kinh độ và bán kính cho phép gắn với cấu hình chấm công của chi nhánh; lần chấm công phải nằm trong đó hoặc khớp mạng WiFi đã cấu hình. Mở Cấu hình chấm công, chọn chi nhánh, rồi đặt tọa độ, bán kính, tùy chọn WiFi và chiến lược phân giải. Nhật ký cấu hình giữ lịch sử thay đổi, rất quan trọng khi nhân viên khiếu nại một lần chấm bị từ chối. Không có cấu hình thì chi nhánh không có hàng rào để thực thi."
          }
        },
        {
          type: "links",
          items: [
            { label: { en: "Open Attendance Configs", vi: "Mở Cấu hình chấm công" }, path: "company_attendance_configs_path" }
          ]
        }
      ]
    },
    {
      slug: "attendance-calculations",
      question: {
        en: "How are late, overtime, half-day, absent, and missing-checkout calculated?",
        vi: "Đi muộn, tăng ca, nửa ngày, vắng và thiếu giờ ra được tính thế nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "The daily attendance process pairs attendance records into work segments, deducts breaks according to the branch strategy, and compares the net minutes with the scheduled shift. It stores late minutes, overtime minutes, and a status such as present, late, half day, absent, or missing checkout. A segment with an unmatched check-in is flagged for review rather than guessed. Night shifts crossing midnight are not fully modelled yet, so keep a crossover shift's check-ins on one calendar day or resolve them manually.",
            vi: "Quy trình chấm công hằng ngày ghép các bản ghi chấm công thành đoạn làm việc, trừ giờ nghỉ theo chiến lược của chi nhánh, rồi so số phút thực với ca đã lên lịch. Hệ thống lưu số phút đi muộn, tăng ca và trạng thái như có mặt, đi muộn, nửa ngày, vắng hoặc thiếu giờ ra. Đoạn có lần vào không khớp giờ ra sẽ bị đánh dấu để xem lại thay vì đoán. Ca qua nửa đêm chưa được mô hình hóa đầy đủ, nên hãy giữ các lần chấm của ca đó trong một ngày lịch hoặc xử lý tay."
          }
        }
      ]
    },
    {
      slug: "attendance-requests",
      question: {
        en: "What are attendance requests, and who approves them?",
        vi: "Yêu cầu chấm công là gì và ai duyệt?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "An attendance request is a manual correction: an employee states the date, check-in, check-out, and reason when the clock did not capture the day correctly. A manager or administrator with attendance permission reviews it; approving creates or updates the attendance day, and rejecting leaves the original record alone. The request keeps the requester, reason, and decision, so the correction is auditable. Employees can file one from the mobile Requests screen.",
            vi: "Yêu cầu chấm công là chỉnh sửa thủ công: nhân viên nêu ngày, giờ vào, giờ ra và lý do khi đồng hồ không ghi đúng ngày đó. Quản lý hoặc quản trị viên có quyền chấm công xem xét; duyệt sẽ tạo hoặc cập nhật ngày chấm công, từ chối sẽ giữ nguyên bản ghi gốc. Yêu cầu lưu người gửi, lý do và quyết định, nên việc sửa có thể kiểm tra. Nhân viên có thể gửi từ màn hình Yêu cầu trên di động."
          }
        },
        {
          type: "links",
          items: [
            { label: { en: "Open Attendance Requests", vi: "Mở Yêu cầu chấm công" }, path: "company_attendance_requests_path" }
          ]
        }
      ]
    },
    {
      slug: "paid-leave-tracking",
      question: {
        en: "How is paid leave tracked?",
        vi: "Nghỉ phép có lương được theo dõi thế nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Each employee has a yearly leave balance with entitled days, and leave requests store the type, status, date range, and number of days. Approved leave is excluded from the on-duty roster, and the employee's mobile Home shows the remaining balance and pending days. The balance and request rows are real records; they are not derived from attendance hours. A leave request workflow for employees to file and managers to approve from the app is still a follow-up.",
            vi: "Mỗi nhân viên có số ngày phép năm với số ngày được hưởng, và các yêu cầu nghỉ lưu loại, trạng thái, khoảng ngày và số ngày. Nghỉ đã duyệt được loại khỏi danh sách đang trực, và Home trên di động của nhân viên hiện số ngày còn lại cùng số ngày đang chờ. Số dư và các dòng yêu cầu là bản ghi thật, không được suy ra từ giờ chấm công. Quy trình để nhân viên gửi và quản lý duyệt nghỉ ngay trong ứng dụng vẫn là việc tiếp theo."
          }
        }
      ]
    },
    {
      slug: "request-leave-app",
      status: "planned",
      question: {
        en: "Can employees request leave in Skycom?",
        vi: "Nhân viên có thể xin nghỉ phép trong Skycom không?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Not through a leave form yet. Employees can see their paid-leave balance and pending days on mobile, and the underlying leave records exist, but there is no screen to file a new leave request or an approval inbox for managers. Until that ships, handle leave requests through your normal HR channel and keep the balance data aligned. The leave request workflow is tracked in the backlog.",
            vi: "Chưa có biểu mẫu xin nghỉ. Nhân viên xem được số ngày phép còn lại và số ngày đang chờ trên di động, và các bản ghi nghỉ phép đã tồn tại, nhưng chưa có màn hình gửi yêu cầu nghỉ mới hay hộp thư duyệt cho quản lý. Trong thời gian đó, hãy xử lý yêu cầu nghỉ qua kênh nhân sự thông thường và giữ dữ liệu số dư khớp. Quy trình xin nghỉ đang được ghi trong backlog."
          }
        }
      ]
    },
    {
      slug: "employee-see-attendance",
      question: {
        en: "Where do employees see their own attendance?",
        vi: "Nhân viên xem chấm công của mình ở đâu?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "On web, use My Profile → Attendance to open the employee's own attendance month and daily rows. On mobile, the Attendance tab shows the same month summary and daily rows read-only, with month navigation. Payroll is a separate surface behind a password gate. Managers see the company-wide Attendance Days and Attendance Months lists, which include every employee they are allowed to read.",
            vi: "Trên web, dùng My Profile → Attendance để mở tháng chấm công và các dòng ngày của chính nhân viên. Trên di động, tab Attendance hiển thị cùng tóm tắt tháng và dòng ngày ở chế độ chỉ đọc, có chuyển tháng. Bảng lương là bề mặt riêng sau cổng mật khẩu. Quản lý thấy danh sách Ngày chấm công và Tháng chấm công toàn công ty, gồm mọi nhân viên họ được phép xem."
          }
        }
      ]
    },
    {
      slug: "attendance-month-stale",
      status: "planned",
      question: {
        en: "Why is my attendance month out of date?",
        vi: "Vì sao tháng chấm công của tôi bị cũ?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Attendance months are summaries of attendance days, and the production scheduled refresh is still a gap: days can be processed, but the monthly totals are not guaranteed to be rebuilt by a nightly refresh. A new check-in or an approved request may therefore show on the day before the month catches up. The platform can be re-run to process the month, but there is no self-service refresh button. The scheduled sync is tracked in the backlog.",
            vi: "Tháng chấm công là bản tổng hợp của các ngày chấm công, và việc làm mới theo lịch trong môi trường thật vẫn còn thiếu: ngày có thể được xử lý, nhưng tổng tháng chưa chắc được xây lại bởi lần làm mới hằng đêm. Vì vậy một lần chấm mới hoặc yêu cầu đã duyệt có thể hiện ở ngày trước khi tháng cập nhật. Nền tảng có thể chạy lại để xử lý tháng, nhưng chưa có nút tự làm mới. Việc đồng bộ theo lịch đang được ghi trong backlog."
          }
        }
      ]
    },
    {
      slug: "mobile-checkout-missing",
      status: "planned",
      question: {
        en: "Can employees check out on mobile?",
        vi: "Nhân viên có thể chấm công ra trên di động không?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Not yet. The mobile Home exposes check-in, but it does not expose check-out or a break action, even though the platform has a check-out service. A missing check-out therefore becomes an attendance request or a manager correction. This is a mobile parity gap, not a deliberate policy; it is tracked in the backlog alongside the attendance month refresh.",
            vi: "Chưa hỗ trợ. Home trên di động có chấm công vào nhưng chưa có chấm công ra hay nghỉ giữa ca, dù nền tảng đã có dịch vụ chấm công ra. Vì vậy thiếu giờ ra sẽ thành yêu cầu chấm công hoặc quản lý sửa tay. Đây là khoảng trống đồng bộ di động, không phải chính sách có chủ đích; đang được ghi trong backlog cùng việc làm mới tháng chấm công."
          }
        }
      ]
    }
  ]
}
