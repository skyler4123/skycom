export default {
  key: "reception",
  icon: "badge",
  title: {
    en: "Reception",
    vi: "Lễ tân"
  },
  questions: [
    {
      slug: "what-reception-tracks",
      question: {
        en: "What does Reception track?",
        vi: "Lễ tân theo dõi những gì?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Reception answers one question at a glance: who is inside, who is waiting, and who is still expected. It tracks guest visits, held parcels, room readiness, today's non-visit appointments, and the receptionist's scheduled shift. It refreshes every 20 seconds without losing your form or filter, and every count comes from a real record rather than a decorative label.",
            vi: "Lễ tân trả lời một câu hỏi trong nháy mắt: ai đang ở trong, ai đang chờ và ai còn dự kiến đến. Màn hình theo dõi lượt khách, bưu phẩm đang giữ, tình trạng phòng, các cuộc hẹn không phải khách trong ngày và ca làm đã lên lịch của lễ tân. Trang tự làm mới mỗi 20 giây mà không mất biểu mẫu hay bộ lọc, và mọi con số đến từ bản ghi thật chứ không phải nhãn trang trí."
          }
        }
      ]
    },
    {
      slug: "what-counts-as-visitor",
      question: {
        en: "What counts as a visitor, and why don’t all bookings appear?",
        vi: "Ai được tính là khách đến và vì sao không phải mọi lượt đặt chỗ đều hiện?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "A visitor is an Event marked as a reception visit and linked to a Customer. A facility booking without a guest is not a visitor, even if it occupies a room, because there is nobody at the front desk to check in. Those bookings appear in the Appointments panel instead of the visitor queue, so the lobby count stays honest. If a guest is missing, attach a customer to the visit rather than changing the booking type.",
            vi: "Khách đến là một Sự kiện được đánh dấu là lượt lễ tân và có liên kết Khách hàng. Một lượt đặt phòng không có khách không phải khách đến, kể cả khi chiếm phòng, vì không có ai ở quầy để check-in. Những lượt đó hiện trong bảng Cuộc hẹn thay vì hàng đợi khách, nên số người ở sảnh vẫn đúng. Nếu thiếu khách, hãy gắn khách hàng vào lượt thay vì đổi loại đặt chỗ."
          }
        }
      ]
    },
    {
      slug: "walk-in-versus-pre-register",
      question: {
        en: "How do walk-in check-in and pre-registration differ?",
        vi: "Check-in khách tại quầy và đăng ký trước khác nhau thế nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Walk-in check-in is for someone standing at the desk now: name and visitor company are required, while host, room, and VIP are optional, and the visit starts in the lobby. Pre-registration is for a future guest: you choose a branch-local date, start time, and optional end time, and the visit starts as Expected. Pre-registration allows a room overlap because it is a plan, not a locked reservation; use Booking when the room must be conflict-checked.",
            vi: "Check-in tại quầy dành cho người đang đứng ở quầy: bắt buộc có tên và công ty của khách, còn người chủ trì, phòng và VIP là tùy chọn; lượt bắt đầu ở trạng thái ở sảnh. Đăng ký trước dành cho khách tương lai: chọn ngày, giờ bắt đầu và giờ kết thúc tùy chọn theo chi nhánh; lượt bắt đầu ở trạng thái Dự kiến. Đăng ký trước cho phép trùng phòng vì đây là kế hoạch, không phải đặt chỗ đã khóa; dùng Booking khi cần kiểm tra xung đột phòng."
          }
        }
      ]
    },
    {
      slug: "reception-statuses",
      question: {
        en: "What do Expected, Lobby, Inside, and Departed mean?",
        vi: "Dự kiến, Ở sảnh, Bên trong và Đã rời có ý nghĩa gì?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Expected means the visit is pending or draft and should start today. Lobby means the guest has arrived and is confirmed but has not gone inside. Inside means the visit is in progress; Departed means it is completed. The actions follow the same order: They've arrived moves Expected to Lobby, Mark inside moves Lobby to Inside, Check out moves Inside to Departed, and Reopen brings a departed visit back inside when it was closed too early.",
            vi: "Dự kiến nghĩa là lượt đang chờ hoặc nháp và dự kiến bắt đầu hôm nay. Ở sảnh nghĩa là khách đã đến và được xác nhận nhưng chưa vào trong. Bên trong nghĩa là lượt đang diễn ra; Đã rời nghĩa là đã hoàn tất. Các thao tác theo cùng thứ tự: Khách đã đến chuyển Dự kiến sang Ở sảnh, Đánh dấu đã vào chuyển Ở sảnh sang Bên trong, Check out chuyển Bên trong sang Đã rời, và Mở lại đưa lượt đã rời trở lại bên trong khi bị đóng quá sớm."
          }
        }
      ]
    },
    {
      slug: "notify-host-and-badge",
      question: {
        en: "How do I notify a host and print a visitor badge?",
        vi: "Làm sao báo người chủ trì và in thẻ khách?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "On a lobby or inside visitor card, choose Notify host. Skycom creates one direct in-app notification for that host and records the time; choosing Notify again creates another notification. If the visit has no host, the action is inert and says there is nobody to notify. Print visitor badge opens the browser print dialog with only that visit's badge, containing company, visitor name and company, host, room, branch, time, and reference. There is no label-printer integration.",
            vi: "Trên thẻ khách đang ở sảnh hoặc bên trong, chọn Báo người chủ trì. Skycom tạo một thông báo trực tiếp trong ứng dụng cho người đó và ghi lại thời gian; chọn Báo lại sẽ tạo thêm một thông báo. Nếu lượt không có người chủ trì, thao tác không hoạt động và báo không có ai để báo. In thẻ khách mở hộp thoại in của trình duyệt chỉ với thẻ của lượt đó, gồm công ty, tên và công ty của khách, người chủ trì, phòng, chi nhánh, thời gian và mã tham chiếu. Không có tích hợp máy in nhãn."
          }
        }
      ]
    },
    {
      slug: "reception-parcels",
      question: {
        en: "How do I log, notify, and hand over a parcel?",
        vi: "Làm sao ghi nhận, báo và trao bưu phẩm?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Choose Log delivery, enter the carrier, the recipient employee, and a short item summary, then save; the parcel appears under Parcels held. Notify sends one direct in-app notification to the recipient and records the time; Mark picked up completes the parcel and removes it from the held count. Parcels are Events with a parcel marker, so they have a real record and an audit trail. There is no locker assignment or waybill scan in this version.",
            vi: "Chọn Ghi nhận giao hàng, nhập đơn vị vận chuyển, nhân viên nhận và mô tả ngắn món hàng, rồi lưu; bưu phẩm xuất hiện trong mục Bưu phẩm đang giữ. Báo sẽ gửi một thông báo trực tiếp trong ứng dụng cho người nhận và ghi thời gian; Đánh dấu đã nhận hoàn tất bưu phẩm và bỏ khỏi số đang giữ. Bưu phẩm là Sự kiện có dấu bưu phẩm, nên có bản ghi và nhật ký thật. Phiên bản này chưa có gán tủ hay quét vận đơn."
          }
        }
      ]
    },
    {
      slug: "reception-room-readiness",
      question: {
        en: "How is room readiness calculated?",
        vi: "Tình trạng phòng sẵn sàng được tính thế nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Reception counts room-like facilities and checks their current and next events. A room is ready when it has no visit or facility event occupying it now; the Rooms card shows ready over all room-like facilities for the branch. The Appointments panel lists today's non-visit facility events separately, so a booked room can be busy without appearing as a visitor. Facilities without a room-like category are not counted in the readiness card.",
            vi: "Lễ tân đếm các cơ sở vật chất giống phòng và kiểm tra sự kiện hiện tại và kế tiếp của chúng. Phòng sẵn sàng khi không có lượt khách hoặc sự kiện cơ sở vật chất nào chiếm phòng lúc này; thẻ Phòng hiển thị số sẵn sàng trên tổng số phòng của chi nhánh. Bảng Cuộc hẹn liệt kê riêng các sự kiện cơ sở vật chất không phải khách trong ngày, nên phòng đã đặt có thể đang bận mà không hiện như khách. Cơ sở vật chất không thuộc danh mục giống phòng không được tính trong thẻ sẵn sàng."
          }
        }
      ]
    },
    {
      slug: "reception-notifications",
      status: "planned",
      question: {
        en: "Why doesn’t Reception send SMS, email, or push?",
        vi: "Vì sao Lễ tân không gửi SMS, email hay push?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Reception notifications are in-app only: one direct notification to the host or parcel recipient, visible in their Skycom inbox. Skycom does not send SMS, email, or mobile push, and it does not call or broadcast to a PA system. This keeps the feature honest: the bell and the inbox are the delivery channel, and the card records when the notification was sent. External delivery channels are tracked in the backlog.",
            vi: "Thông báo Lễ tân chỉ ở trong ứng dụng: một thông báo trực tiếp cho người chủ trì hoặc người nhận bưu phẩm, hiển thị trong hộp thư Skycom của họ. Skycom không gửi SMS, email hay push di động, và không gọi điện hay phát loa. Điều này giữ tính trung thực: chuông và hộp thư là kênh gửi, còn thẻ ghi lại thời điểm gửi. Các kênh gửi bên ngoài đang được ghi trong backlog."
          }
        }
      ]
    }
  ]
}
