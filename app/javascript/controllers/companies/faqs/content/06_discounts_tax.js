export default {
  key: "discounts_tax",
  icon: "sell",
  title: {
    en: "Discounts & tax",
    vi: "Giảm giá & thuế"
  },
  questions: [
    {
      slug: "campaign-versus-code",
      question: {
        en: "What is a discount campaign vs a discount code?",
        vi: "Chiến dịch giảm giá và mã giảm giá khác nhau thế nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "A campaign is the rule: fixed amount or percentage, validity window, optional budget, and a prefix. A code is one single-use coupon generated under that campaign. The campaign decides whether a code can be applied; the code records which order, customer, employee, and invoice used it. You can pause a campaign without deleting its codes, and you can see every code's state in the campaign detail.",
            vi: "Chiến dịch là quy tắc: giảm số tiền cố định hoặc phần trăm, thời gian hiệu lực, ngân sách tùy chọn và tiền tố. Mã là một phiếu dùng một lần được tạo dưới chiến dịch đó. Chiến dịch quyết định mã có được áp dụng hay không; mã ghi lại đơn hàng, khách hàng, nhân viên và hóa đơn đã dùng. Bạn có thể tạm dừng chiến dịch mà không xóa các mã, và xem trạng thái từng mã trong chi tiết chiến dịch."
          }
        }
      ]
    },
    {
      slug: "create-campaign-and-codes",
      question: {
        en: "How do I create a campaign and generate codes?",
        vi: "Làm sao tạo chiến dịch và tạo mã?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Open Discounts, create a campaign with its type, value, prefix, validity window, and optional budget, then choose how many codes to generate. Skycom creates unique prefix-based codes in bulk and shows them in the campaign detail, where you can copy or export them. A code is single-use per company and cannot be reused after it is consumed. Keep the campaign active only while you want codes to be redeemable.",
            vi: "Mở Giảm giá, tạo chiến dịch với loại, giá trị, tiền tố, thời gian hiệu lực và ngân sách tùy chọn, sau đó chọn số lượng mã cần tạo. Skycom tạo hàng loạt mã duy nhất theo tiền tố và hiển thị trong chi tiết chiến dịch, nơi bạn có thể sao chép hoặc xuất. Mã dùng một lần cho mỗi công ty và không thể dùng lại sau khi đã tiêu thụ. Chỉ để chiến dịch hoạt động khi bạn muốn mã còn dùng được."
          }
        },
        {
          type: "links",
          items: [
            { label: { en: "Open Discounts", vi: "Mở Giảm giá" }, path: "company_discount_groups_path" }
          ]
        }
      ]
    },
    {
      slug: "discount-statuses",
      question: {
        en: "What do unused, pending, used, and expired mean?",
        vi: "Trạng thái chưa dùng, đang giữ, đã dùng và hết hạn có ý nghĩa gì?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Unused means the code is available. Pending means POS reserved it on an open order but the invoice is not paid yet. Used means the invoice was paid and the code is consumed. Expired is a stored state for a code past its window; enforcement today happens when someone tries to apply the code, not by an automatic sweep. A pending code can return to unused if the order is voided or the payment is cancelled.",
            vi: "Chưa dùng nghĩa là mã còn khả dụng. Đang giữ nghĩa là POS đã giữ mã trên một đơn đang mở nhưng hóa đơn chưa thanh toán. Đã dùng nghĩa là hóa đơn đã thanh toán và mã đã bị tiêu thụ. Hết hạn là trạng thái lưu trữ cho mã đã quá thời gian; việc thực thi hiện diễn ra khi có người áp dụng mã, không phải bằng tiến trình quét tự động. Mã đang giữ có thể trở về chưa dùng nếu đơn bị hủy hoặc thanh toán bị hủy."
          }
        }
      ]
    },
    {
      slug: "code-stopped-working",
      question: {
        en: "Why did a code stop working?",
        vi: "Vì sao một mã đã ngừng hoạt động?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Check the campaign first: it must be active, inside its start and end window, and under its budget. Then check the code: it must still be unused, and the order currency must match the campaign currency. A code that is pending on another open order is not available, and a code that was used cannot be applied again. If all of those look correct, confirm the order has a non-zero subtotal and that the code belongs to this company.",
            vi: "Kiểm tra chiến dịch trước: chiến dịch phải đang hoạt động, trong thời gian bắt đầu và kết thúc, và chưa vượt ngân sách. Sau đó kiểm tra mã: mã phải còn chưa dùng, và tiền tệ của đơn phải khớp tiền tệ chiến dịch. Mã đang được giữ trên một đơn mở khác thì không khả dụng, và mã đã dùng không thể áp dụng lại. Nếu mọi thứ có vẻ đúng, hãy xác nhận đơn có tạm tính lớn hơn 0 và mã thuộc đúng công ty này."
          }
        }
      ]
    },
    {
      slug: "discount-on-void-refund",
      question: {
        en: "What happens to a code when a sale is voided or refunded?",
        vi: "Mã giảm giá ra sao khi đơn bị hủy hoặc hoàn tiền?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "A reserved code is released when the order is voided, when the payment is cancelled, or when a QR payment is abandoned before confirmation. A consumed code is reverted if a paid invoice later leaves the paid state through the refund or void path, and the campaign budget is refunded at the same time. The code then becomes available again unless its campaign window or budget no longer allows it.",
            vi: "Mã đang giữ sẽ được giải phóng khi đơn bị hủy, khi thanh toán bị hủy, hoặc khi thanh toán QR bị bỏ trước khi xác nhận. Mã đã tiêu thụ sẽ được hoàn lại nếu hóa đơn đã thanh toán sau đó rời trạng thái đã thanh toán qua đường hoàn tiền hoặc hủy, và ngân sách chiến dịch cũng được hoàn tương ứng. Mã sau đó trở lại khả dụng trừ khi thời gian hoặc ngân sách chiến dịch không còn cho phép."
          }
        }
      ]
    },
    {
      slug: "set-pos-tax-rate",
      question: {
        en: "Where do I set the tax name and rate used by POS?",
        vi: "Đặt tên và mức thuế POS dùng ở đâu?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Open Tax → Tax Config and set the POS tax name and rate. POS reads that one rate, applies it to the discounted subtotal, and snapshots the name and rate onto the order and invoice, so the receipt and the books agree even after a later change. Setting the rate to zero hides the tax row instead of printing a zero. The Tax Config page also owns the reporting sources, date basis, excluded statuses, and branch filters used by Tax Data.",
            vi: "Mở Thuế → Cấu hình thuế và đặt tên cùng mức thuế POS. POS đọc một mức đó, áp lên tạm tính sau giảm giá, và sao lưu tên cùng mức vào đơn hàng và hóa đơn, nên biên lai và sổ sách khớp nhau kể cả sau khi đổi thuế. Đặt mức bằng 0 sẽ ẩn dòng thuế thay vì in số 0. Trang Cấu hình thuế cũng quản lý nguồn báo cáo, cơ sở ngày, trạng thái loại trừ và bộ lọc chi nhánh mà Dữ liệu thuế dùng."
          }
        },
        {
          type: "links",
          items: [
            { label: { en: "Open Tax Config", vi: "Mở Cấu hình thuế" }, path: "company_tax_config_path" }
          ]
        }
      ]
    },
    {
      slug: "tax-data",
      question: {
        en: "What is Tax Data, and which documents does it include?",
        vi: "Dữ liệu thuế là gì và gồm những chứng từ nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Tax Data is a read-only reporting surface for the documents selected in Tax Config: sales invoices, purchases, and stock exports. It shows the period total and the detail lists, filtered by the configured date basis, excluded statuses, and branches. It is not a tax filing engine and does not calculate jurisdiction-specific rules; it helps you collect the figures your accountant needs. Change the sources in Tax Config if a document type should not appear.",
            vi: "Dữ liệu thuế là bề mặt báo cáo chỉ đọc cho các chứng từ được chọn trong Cấu hình thuế: hóa đơn bán hàng, mua hàng và xuất kho. Trang hiển thị tổng theo giai đoạn và danh sách chi tiết, lọc theo cơ sở ngày, trạng thái loại trừ và chi nhánh đã cấu hình. Đây không phải công cụ khai thuế và không tự tính quy tắc riêng của từng khu vực; trang giúp bạn thu thập số liệu kế toán cần. Hãy đổi nguồn trong Cấu hình thuế nếu một loại chứng từ không nên xuất hiện."
          }
        },
        {
          type: "links",
          items: [
            { label: { en: "Open Tax Data", vi: "Mở Dữ liệu thuế" }, path: "company_tax_path" }
          ]
        }
      ]
    },
    {
      slug: "per-product-tax",
      status: "planned",
      question: {
        en: "Can different products use different tax rates?",
        vi: "Các sản phẩm khác nhau có thể dùng mức thuế khác nhau không?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Not in POS today. POS uses one company-wide Tax Config rate added on top of the discounted subtotal, so every line in a sale carries the same rate. Mixed-rate sales and tax-inclusive pricing would need per-line tax totals and the TaxCode owner wired into the POS pipeline; that work is tracked in the backlog. For now, if you sell mixed-rate goods, keep the POS rate as the default and handle the exception in your accounting process.",
            vi: "Hiện POS chưa hỗ trợ. POS dùng một mức thuế chung của công ty cộng lên tạm tính sau giảm giá, nên mọi dòng trong một đơn đều cùng mức. Bán hàng nhiều mức thuế và giá đã gồm thuế sẽ cần tổng thuế theo từng dòng và đưa TaxCode vào luồng POS; công việc này đang được ghi trong backlog. Trong thời gian đó, nếu bán hàng nhiều mức thuế, hãy giữ mức POS làm mặc định và xử lý ngoại lệ trong quy trình kế toán."
          }
        }
      ]
    }
  ]
}
