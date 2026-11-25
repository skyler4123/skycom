export default {
  key: "booking_facilities",
  icon: "meeting_room",
  title: {
    en: "Booking & facilities",
    vi: "Đặt chỗ & cơ sở vật chất"
  },
  questions: [
    {
      slug: "what-is-a-booking",
      question: {
        en: "What is a booking in Skycom?",
        vi: "Một lượt đặt chỗ trong Skycom là gì?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "A booking is an Event with a time window, a branch, and a linked Facility; there is no separate reservation table. The event can also link a host employee, a customer, services, stock needs, and an attendee count. The Booking console shows those events as a day timeline and lets a host inspect, extend, end, or cancel one. Because it is an Event, the same record is visible in the Calendar and Events pages, not duplicated.",
            vi: "Lượt đặt chỗ là một Sự kiện có khung giờ, chi nhánh và Cơ sở vật chất được liên kết; không có bảng đặt chỗ riêng. Sự kiện cũng có thể liên kết nhân viên chủ trì, khách hàng, dịch vụ, nhu cầu tồn và số người tham dự. Màn hình Booking hiển thị các sự kiện đó theo dòng thời gian trong ngày và cho lễ tân xem, gia hạn, kết thúc hoặc hủy. Vì là Sự kiện, cùng bản ghi xuất hiện trong Lịch và Sự kiện, không bị nhân bản."
          }
        }
      ]
    },
    {
      slug: "create-reservation",
      question: {
        en: "How do I create a reservation?",
        vi: "Làm sao tạo một lượt đặt chỗ?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Open Booking for the branch, then use the Instant Reservation form: enter a name, choose a real facility, optionally choose a host and search for a customer, then set the start and end times. Confirm & Lock Booking creates the event and its links in one step. You can also start from 15-Min Quick Room to prefill a short slot, or click an empty calendar slot on the Events board to open a prefilled create form.",
            vi: "Mở Booking cho chi nhánh, sau đó dùng biểu mẫu Đặt chỗ nhanh: nhập tên, chọn cơ sở vật chất thật, tùy chọn người chủ trì và tìm khách hàng, rồi đặt giờ bắt đầu và kết thúc. Confirm & Lock Booking tạo sự kiện và các liên kết trong một bước. Bạn cũng có thể bắt đầu từ 15-Min Quick Room để điền sẵn khung ngắn, hoặc bấm một ô trống trên bảng Sự kiện để mở biểu mẫu tạo đã điền sẵn."
          }
        }
      ]
    },
    {
      slug: "prevent-double-booking",
      question: {
        en: "How does Skycom prevent double bookings?",
        vi: "Skycom chống đặt trùng như thế nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "The Booking console checks for another non-cancelled, non-completed booking of the same facility whose time overlaps the new range. It locks the facility row during the check and refuses the save with an error that names the facility and the conflicting time. Back-to-back bookings are allowed because their ranges only touch, they do not overlap. The Calendar and Events CRUD pages are deliberately looser: they warn about an overlap but allow the save, so use the Booking console for front-desk reservations.",
            vi: "Màn hình Booking kiểm tra một lượt đặt khác chưa hủy, chưa hoàn tất của cùng cơ sở vật chất có thời gian chồng lấn với khung mới. Hệ thống khóa dòng cơ sở vật chất trong lúc kiểm tra và từ chối lưu kèm lỗi nêu rõ cơ sở vật chất và thời gian xung đột. Đặt nối tiếp được phép vì hai khung chỉ chạm nhau, không chồng lấn. Trang Lịch và Sự kiện cố ý lỏng hơn: có cảnh báo chồng lấn nhưng vẫn cho lưu, nên hãy dùng màn hình Booking cho việc đặt chỗ tại quầy."
          }
        }
      ]
    },
    {
      slug: "back-to-back-bookings",
      question: {
        en: "Can bookings be back-to-back?",
        vi: "Có thể đặt chỗ nối tiếp nhau không?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Yes. A booking that starts exactly when the previous one ends is allowed; the conflict rule is a true overlap, not a touch. This lets a room move from one meeting to the next without an artificial gap. The inspector and timeline show both bookings, and Extend will refuse if the extra 30 minutes would run into the next booking.",
            vi: "Có. Lượt đặt bắt đầu đúng lúc lượt trước kết thúc vẫn được phép; quy tắc xung đột là chồng lấn thật, không phải chạm mép. Nhờ vậy một phòng có thể chuyển từ cuộc họp này sang cuộc họp tiếp theo mà không cần khoảng trống nhân tạo. Bảng xem và dòng thời gian hiển thị cả hai lượt, và Gia hạn sẽ từ chối nếu thêm 30 phút chạy vào lượt kế tiếp."
          }
        }
      ]
    },
    {
      slug: "extend-end-cancel-booking",
      question: {
        en: "How do I extend, end, or cancel a booking?",
        vi: "Làm sao gia hạn, kết thúc hoặc hủy một lượt đặt chỗ?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Select the booking on the timeline to open the inspector. Extend +30m moves the end time and checks the next booking; End & release marks the booking done and frees the space, ending it at the current time when it is in progress; Cancel asks for confirmation and then cancels the event. All three act on the same event the timeline shows, so the inspector and the block never tell different stories.",
            vi: "Chọn lượt đặt trên dòng thời gian để mở bảng xem. Gia hạn +30 phút đẩy giờ kết thúc và kiểm tra lượt kế tiếp; Kết thúc & giải phóng đánh dấu lượt đặt hoàn tất và trả không gian, kết thúc tại thời điểm hiện tại nếu đang diễn ra; Hủy sẽ yêu cầu xác nhận rồi hủy sự kiện. Cả ba thao tác trên cùng sự kiện mà dòng thời gian hiển thị, nên bảng xem và khối đặt chỗ không bao giờ nói khác nhau."
          }
        }
      ]
    },
    {
      slug: "booking-day-window",
      question: {
        en: "Why does the timeline use 08:00–18:00, and how do I see after-hours bookings?",
        vi: "Vì sao dòng thời gian dùng 08:00–18:00 và làm sao xem lượt đặt ngoài giờ?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "The 08:00–18:00 grid is a fixed, labelled day window, not your branch's real opening hours. A booking outside it is not hidden: the timeline shows a tag such as “1 booking outside this window” with the time, and clicking the tag selects that booking in the inspector. Real branch opening hours are not modelled yet, so the window is a display convenience rather than a booking restriction.",
            vi: "Khung 08:00–18:00 là cửa sổ hiển thị cố định có nhãn, không phải giờ mở cửa thật của chi nhánh. Lượt đặt ngoài khung không bị ẩn: dòng thời gian hiện thẻ như “1 lượt đặt ngoài khung này” kèm thời gian, và bấm thẻ sẽ chọn lượt đó trong bảng xem. Giờ mở cửa thật của chi nhánh chưa được mô hình hóa, nên khung này chỉ là tiện ích hiển thị, không phải giới hạn đặt chỗ."
          }
        }
      ]
    },
    {
      slug: "booking-versus-events",
      question: {
        en: "What is the difference between Booking and the Calendar/Events pages, and why did an overlapping Event save?",
        vi: "Booking khác Lịch/Sự kiện thế nào và vì sao một Sự kiện chồng lấn vẫn lưu được?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "The Booking console is the front-desk reservation flow: it checks conflicts, locks the facility, and blocks an overlap. Calendar and Events are the general scheduling surfaces: they show the same events, let you create any event, and follow the warn-but-allow contract. They warn when a facility or host already has something in that window, but they save unless a real validation fails. If two records must never overlap, create or move them from Booking.",
            vi: "Màn hình Booking là luồng đặt chỗ tại quầy: kiểm tra xung đột, khóa cơ sở vật chất và chặn chồng lấn. Lịch và Sự kiện là bề mặt lập lịch chung: hiển thị cùng các sự kiện, cho tạo bất kỳ sự kiện nào và theo cơ chế cảnh báo nhưng vẫn cho lưu. Chúng cảnh báo khi cơ sở vật chất hoặc người chủ trì đã có việc trong khung đó, nhưng vẫn lưu trừ khi kiểm tra thật thất bại. Nếu hai bản ghi không được chồng lấn, hãy tạo hoặc di chuyển chúng từ Booking."
          }
        }
      ]
    },
    {
      slug: "recurring-bookings-deposits",
      status: "planned",
      question: {
        en: "Can I create recurring bookings or take a deposit?",
        vi: "Có thể tạo đặt chỗ định kỳ hoặc thu tiền cọc không?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Not yet. The Booking console creates one reservation at a time; it does not collect a deposit or payment, and there is no recurrence rule. Create each occurrence manually, and record any money in POS if you need a payment trail. Recurring series would need a recurrence model, and deposits would need a payment step tied to the booking. Both are tracked in the backlog and this answer will change when they ship.",
            vi: "Chưa hỗ trợ. Màn hình Booking tạo từng lượt đặt một; không thu tiền cọc hoặc thanh toán, và không có quy tắc lặp. Hãy tạo từng lượt thủ công, và ghi nhận tiền trong POS nếu cần dấu vết thanh toán. Đặt chỗ định kỳ sẽ cần mô hình lặp, còn tiền cọc sẽ cần bước thanh toán gắn với lượt đặt. Cả hai đang được ghi trong backlog và câu trả lời này sẽ thay đổi khi ra mắt."
          }
        }
      ]
    }
  ]
}
