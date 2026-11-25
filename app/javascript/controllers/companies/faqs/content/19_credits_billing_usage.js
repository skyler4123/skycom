export default {
  key: "credits_billing_usage",
  icon: "account_balance_wallet",
  title: {
    en: "Credits, billing & usage",
    vi: "Tín dụng, thanh toán & mức dùng"
  },
  questions: [
    {
      slug: "how-skycom-charges",
      question: {
        en: "How does Skycom charge for usage?",
        vi: "Skycom tính phí sử dụng như thế nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Skycom uses prepaid credits, not subscription tiers. A company wallet holds a main balance of purchased credits and a promo balance of granted credits, and metered actions deduct from it after a successful request. There is no invoice-per-action; the wallet is the billing boundary, and Billing shows the purchase history behind the balance. A new company receives a promotional balance so it can start working immediately.",
            vi: "Skycom dùng tín dụng trả trước, không dùng gói thuê bao. Ví công ty giữ số dư chính từ tín dụng đã mua và số dư khuyến mãi từ tín dụng được tặng; các thao tác tính phí sẽ trừ sau một yêu cầu thành công. Không có hóa đơn cho từng thao tác; ví là ranh giới thanh toán, và trang Thanh toán hiện lịch sử mua tạo nên số dư. Công ty mới nhận số dư khuyến mãi để dùng được ngay."
          }
        }
      ]
    },
    {
      slug: "main-versus-promo-credits",
      question: {
        en: "What is the difference between main and promo credits?",
        vi: "Tín dụng chính và tín dụng khuyến mãi khác nhau thế nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Main credits are purchased through a top-up and land in the main balance. Promo credits are granted by Skycom, a signup bonus, or a promotional campaign and land in the promo balance. Deductions spend the promo balance first, then the main balance, so granted credits are used before purchased ones. Both balances can go negative in total, and the sum decides whether the company is active or suspended.",
            vi: "Tín dụng chính được mua qua lần nạp và vào số dư chính. Tín dụng khuyến mãi do Skycom tặng, thưởng đăng ký hoặc chiến dịch khuyến mãi và vào số dư khuyến mãi. Việc trừ dùng số dư khuyến mãi trước, rồi đến số dư chính, nên tín dụng được tặng được dùng trước tín dụng đã mua. Cả hai số dư có thể âm khi cộng lại, và tổng quyết định công ty đang hoạt động hay bị tạm ngưng."
          }
        }
      ]
    },
    {
      slug: "which-actions-consume-credits",
      question: {
        en: "Which actions consume credits, and when exactly?",
        vi: "Thao tác nào tiêu tín dụng và trừ chính xác khi nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Skycom enables metering only for specific actions, and Skycom's rate table sets the cost. The action metered today is Dashboard access at two credits per successful data load; the rate table also defines costs for order creation and customer creation, but those charges are not active yet. A request is charged only after it succeeds, not for a failed request, and a response served from Skycom's short-lived data cache still counts as an access. The charge never blocks the page response.",
            vi: "Skycom chỉ bật tính phí cho một số thao tác cụ thể, và bảng giá của Skycom đặt chi phí. Thao tác đang được tính hôm nay là truy cập Bảng điều khiển với hai tín dụng mỗi lần tải dữ liệu thành công; bảng giá cũng định nghĩa chi phí tạo đơn hàng và tạo khách hàng, nhưng các khoản đó chưa hoạt động. Yêu cầu chỉ bị trừ sau khi thành công, không trừ khi thất bại, và phản hồi lấy từ bộ đệm dữ liệu ngắn hạn của Skycom vẫn tính là một lần truy cập. Việc trừ không bao giờ chặn phản hồi trang."
          }
        }
      ]
    },
    {
      slug: "zero-or-negative-balance",
      question: {
        en: "What happens when the balance reaches zero or goes negative?",
        vi: "Điều gì xảy ra khi số dư về 0 hoặc âm?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Deductions do not stop at zero; the wallet can go negative, and the total balance derives the company's status. At zero or below, the company is suspended: normal web, data, and mobile surfaces are blocked, while Top Up, Billing, Usage, and the FAQ remain available so the owner can recover. Topping up raises the balance and reactivates the company. There is no separate debt balance and no automatic credit card charge.",
            vi: "Việc trừ không dừng ở 0; ví có thể âm, và tổng số dư quyết định trạng thái công ty. Khi bằng 0 hoặc thấp hơn, công ty bị tạm ngưng: các bề mặt web, dữ liệu và di động thông thường bị chặn, trong khi Nạp tiền, Thanh toán, Mức dùng và FAQ vẫn mở để chủ sở hữu khắc phục. Nạp tiền sẽ tăng số dư và kích hoạt lại công ty. Không có số dư nợ riêng và không tự động trừ thẻ tín dụng."
          }
        }
      ]
    },
    {
      slug: "top-up-options",
      question: {
        en: "How do I top up, and which payment options are available?",
        vi: "Làm sao nạp tiền và có những phương thức nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Open Top Up from the System group. The page shows the country-based credit tiers and the company payment options, then starts the selected gateway flow; a completed company order creates the invoice and transaction and credits the wallet. Cash and mock QR/redirect methods are set up for you, while external gateways stay inactive until merchant credentials are configured. The available tiers depend on the company's country, so the same money can buy a different credit amount in another market.",
            vi: "Mở Nạp tiền trong nhóm Hệ thống. Trang hiện các mức tín dụng theo quốc gia và phương thức thanh toán của công ty, rồi bắt đầu luồng cổng đã chọn; đơn hàng công ty hoàn tất sẽ tạo hóa đơn, giao dịch và cộng vào ví. Tiền mặt và QR/chuyển hướng mô phỏng được tạo sẵn, còn cổng bên ngoài vẫn tắt cho đến khi cấu hình thông tin merchant. Các mức có sẵn phụ thuộc quốc gia công ty, nên cùng số tiền có thể mua lượng tín dụng khác ở thị trường khác."
          }
        },
        {
          type: "links",
          items: [
            { label: { en: "Open Top Up", vi: "Mở Nạp tiền" }, path: "new_company_top_up_path" }
          ]
        }
      ]
    },
    {
      slug: "usage-and-billing-pages",
      question: {
        en: "What do the Usage and Billing pages show?",
        vi: "Trang Mức dùng và Thanh toán hiển thị gì?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Usage shows the wallet snapshot, the last seven daily totals, today's live counter, and the monthly total; an optional short logging window lists the individual usage rows. Billing shows the wallet snapshot and the purchase history behind it: company orders, their invoices, and transactions. Both are read-only and stay available while the company is suspended, because they are how the owner understands and fixes the balance.",
            vi: "Mức dùng hiện ảnh chụp ví, tổng bảy ngày gần nhất, bộ đếm trực tiếp hôm nay và tổng tháng; một cửa sổ ghi chi tiết ngắn tùy chọn liệt kê từng dòng sử dụng. Thanh toán hiện ảnh chụp ví và lịch sử mua phía sau: đơn hàng công ty, hóa đơn và giao dịch. Cả hai chỉ đọc và vẫn mở khi công ty bị tạm ngưng, vì đây là cách chủ sở hữu hiểu và sửa số dư."
          }
        },
        {
          type: "links",
          items: [
            { label: { en: "Open Usage", vi: "Mở Mức dùng" }, path: "company_usage_path" },
            { label: { en: "Open Billing", vi: "Mở Thanh toán" }, path: "company_billing_path" }
          ]
        }
      ]
    },
    {
      slug: "jobs-and-imports-free",
      question: {
        en: "Are imports or background jobs charged?",
        vi: "Nhập dữ liệu hoặc tiến trình nền có bị tính phí không?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "No. Only a user action can deduct credits. Background processing, imports, data migrations, order completion, demo data, and promo campaigns are free-credit. Those processes may still grant credits, such as a top-up completion or a promo campaign, and they may count usage, but they never move credits out. This keeps a suspended company's background processing from digging a deeper negative balance.",
            vi: "Không. Chỉ thao tác của người dùng mới trừ được tín dụng. Xử lý nền, nhập dữ liệu, chuyển dữ liệu, hoàn tất đơn, dữ liệu demo và chiến dịch khuyến mãi là miễn phí tín dụng. Các tiến trình đó vẫn có thể tặng tín dụng, như hoàn tất nạp tiền hoặc chiến dịch khuyến mãi, và có thể ghi nhận mức dùng, nhưng không bao giờ chuyển tín dụng ra. Điều này ngăn xử lý nền của công ty bị tạm ngưng làm số dư âm sâu hơn."
          }
        }
      ]
    }
  ]
}
