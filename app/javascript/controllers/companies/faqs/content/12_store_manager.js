export default {
  key: "store_manager",
  icon: "storefront",
  title: {
    en: "Store Manager",
    vi: "Quản lý cửa hàng"
  },
  questions: [
    {
      slug: "what-store-manager-shows",
      question: {
        en: "What does Store Manager show?",
        vi: "Quản lý cửa hàng hiển thị những gì?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Store Manager is the branch command screen for one retail day. It answers four questions at a glance: how much have we sold, what still has to be handed to a customer, what is nearly empty on the shelf, and who is working. It also holds the shift close and the shelf replenishment actions, while payment, void, and warehouse counting stay on POS and Inventory.",
            vi: "Quản lý cửa hàng là màn hình chỉ huy chi nhánh cho một ngày bán lẻ. Trang trả lời bốn câu hỏi trong nháy mắt: đã bán được bao nhiêu, còn phải trao cho khách những gì, kệ hàng nào gần hết và ai đang làm việc. Trang cũng chứa việc đóng ca và bổ sung kệ, còn thanh toán, hủy và kiểm kê kho vẫn ở POS và Inventory."
          }
        }
      ]
    },
    {
      slug: "store-manager-kpis",
      question: {
        en: "How are gross sales, cashiers, and on-duty staff calculated?",
        vi: "Doanh thu gộp, thu ngân và nhân sự đang trực được tính thế nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Gross sales is the sum of paid invoice totals for the branch's calendar day, including tax and order-level adjustments; the comparison uses the same formula for the previous day and stays blank when yesterday had no sales. Cashiers are the distinct employees credited with at least one paid order that day. On duty counts employees checked in on a scheduled shift covering now, excluding approved leave; the shift chip names the real scheduled shift or says none is scheduled.",
            vi: "Doanh thu gộp là tổng hóa đơn đã thanh toán trong ngày lịch của chi nhánh, gồm thuế và điều chỉnh cấp đơn; phần so sánh dùng cùng công thức cho ngày trước và để trống nếu hôm qua không có bán hàng. Thu ngân là các nhân viên khác nhau được ghi nhận ít nhất một đơn đã thanh toán trong ngày. Đang trực đếm nhân viên đã chấm công trong ca đã lên lịch phủ thời điểm hiện tại, trừ nghỉ phép đã duyệt; nhãn ca ghi tên ca thật hoặc báo chưa có ca."
          }
        }
      ]
    },
    {
      slug: "fulfilment-queue",
      question: {
        en: "How do I mark an order ready and hand it over?",
        vi: "Làm sao đánh dấu đơn sẵn sàng và bàn giao?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Use the fulfilment queue on Store Manager: filter by all open, click and collect, local delivery, or completed, and search by order code, customer, channel, or status. Mark ready stores the fulfilment status ready; Hand over stores handed over with a timestamp and removes the order from the open queue. The completed tab keeps what was handed over for the selected day. The queue loads 50 rows at a time from the server, so search works on the whole day's set, not only the visible page.",
            vi: "Dùng hàng đợi bàn giao trên Quản lý cửa hàng: lọc theo tất cả đơn mở, đặt và nhận, giao hàng hoặc đã hoàn tất; tìm theo mã đơn, khách hàng, kênh hoặc trạng thái. Đánh dấu sẵn sàng lưu trạng thái bàn giao là sẵn sàng; Bàn giao lưu trạng thái đã bàn giao kèm thời gian và bỏ đơn khỏi hàng đợi mở. Tab đã hoàn tất giữ các đơn đã bàn giao trong ngày đã chọn. Hàng đợi tải 50 dòng mỗi lần từ máy chủ, nên tìm kiếm áp dụng cho toàn bộ đơn trong ngày, không chỉ trang đang thấy."
          }
        }
      ]
    },
    {
      slug: "hand-over-unpaid-order",
      question: {
        en: "Why can’t I hand over an unpaid order?",
        vi: "Vì sao không thể bàn giao đơn chưa thanh toán?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Handover means goods leave the branch, so Skycom requires the invoice to be paid first. An unpaid order stays in the queue and can be marked ready, but the hand-over action will not complete until payment is recorded. Take the payment in POS, then return to the queue and hand it over. This prevents stock leaving without a matching payment and keeps gross sales and handed-over orders consistent.",
            vi: "Bàn giao nghĩa là hàng rời chi nhánh, nên Skycom yêu cầu hóa đơn được thanh toán trước. Đơn chưa thanh toán vẫn ở hàng đợi và có thể đánh dấu sẵn sàng, nhưng thao tác bàn giao sẽ không hoàn tất cho đến khi có thanh toán. Hãy thu tiền ở POS, rồi quay lại hàng đợi để bàn giao. Điều này ngăn hàng rời đi mà không có khoản thanh toán tương ứng và giữ doanh thu gộp khớp với đơn đã bàn giao."
          }
        }
      ]
    },
    {
      slug: "shelf-replenishment",
      question: {
        en: "How does shelf replenishment create a transfer or purchase?",
        vi: "Bổ sung kệ tạo phiếu chuyển kho hoặc mua hàng thế nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "The Shelf replenishment table lists branch stock rows at or below their reorder point, with the warehouse availability beside each one. The floor action opens a sheet where you enter a quantity and choose a source warehouse for a transfer or a supplier for a purchase, then confirm explicitly. Skycom creates the document once and shows its code in the Stage column; pressing the action again opens that same document instead of creating a duplicate.",
            vi: "Bảng Bổ sung kệ liệt kê các dòng tồn của chi nhánh ở hoặc dưới điểm đặt hàng lại, kèm lượng khả dụng ở kho bên cạnh. Thao tác trên kệ mở một bảng để nhập số lượng và chọn kho nguồn cho phiếu chuyển hoặc nhà cung cấp cho đơn mua, rồi xác nhận rõ ràng. Skycom tạo chứng từ một lần và hiện mã ở cột Giai đoạn; bấm lại sẽ mở đúng chứng từ đó thay vì tạo trùng."
          }
        }
      ]
    },
    {
      slug: "close-shift",
      question: {
        en: "How do I close a shift, and how is variance calculated?",
        vi: "Làm sao đóng ca và chênh lệch được tính thế nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Choose Close shift (today only), enter the opening float and the counted cash, and review the sheet: sales by tender, order count, discounts, tax, expected cash, still to hand over, shelf rows short, and checked-in staff. Expected cash is the float plus cash received minus change given; variance is counted cash minus expected cash and is computed, not typed. Save and close stores one close per branch and business date, and Print prints only the sheet.",
            vi: "Chọn Đóng ca (chỉ hôm nay), nhập tiền đầu ca và tiền mặt đã đếm, rồi xem lại bảng: doanh số theo phương thức, số đơn, giảm giá, thuế, tiền mặt dự kiến, còn phải bàn giao, số dòng kệ thiếu và nhân sự đã chấm công. Tiền mặt dự kiến là tiền đầu ca cộng tiền mặt nhận trừ tiền thừa; chênh lệch là tiền đếm trừ tiền dự kiến và được tính tự động, không nhập tay. Lưu và đóng lưu một bản cho mỗi chi nhánh và ngày làm việc, và In chỉ in bảng đó."
          }
        }
      ]
    },
    {
      slug: "past-shift-close",
      question: {
        en: "Can I view or edit a past shift close?",
        vi: "Có thể xem hoặc sửa bản đóng ca cũ không?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "You can view a saved past close read-only by choosing the date; the only action is View close report. You cannot edit it, because it is a stored snapshot of the shift's money and staffing. If a past date has no saved close, the shelf area says no snapshot was saved instead of pretending today's stock is history. Current-day close can be saved again if you need to correct it before the day ends.",
            vi: "Bạn có thể xem bản đóng ca cũ đã lưu ở chế độ chỉ đọc bằng cách chọn ngày; thao tác duy nhất là Xem báo cáo đóng ca. Không thể sửa vì đây là ảnh chụp đã lưu của tiền và nhân sự trong ca. Nếu ngày cũ chưa có bản đóng ca, phần kệ sẽ báo chưa lưu ảnh chụp thay vì giả vờ tồn kho hôm nay là lịch sử. Bản đóng ca hôm nay có thể lưu lại nếu cần sửa trước khi hết ngày."
          }
        }
      ]
    },
    {
      slug: "footfall-sensor",
      status: "planned",
      question: {
        en: "Why is there no footfall sensor?",
        vi: "Vì sao không có cảm biến lượng khách vào cửa?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Skycom has no door-sensor integration, so it does not invent visitors, conversion, or dwell time. Store Manager shows one honest line: No door sensor, followed by the real count of distinct customers with a paid order that day. That buyer count is useful, but it is not the same as everyone who walked in. A sensor integration would be a hardware and data-ingestion project, tracked in the backlog.",
            vi: "Skycom không tích hợp cảm biến cửa, nên không bịa số khách vào, tỷ lệ chuyển đổi hay thời gian dừng. Quản lý cửa hàng hiện một dòng trung thực: Không có cảm biến cửa, kèm số khách hàng khác nhau đã có đơn thanh toán trong ngày. Số người mua này hữu ích nhưng không giống số người đã bước vào. Tích hợp cảm biến sẽ là một dự án phần cứng và nhập dữ liệu, đang được ghi trong backlog."
          }
        }
      ]
    }
  ]
}
