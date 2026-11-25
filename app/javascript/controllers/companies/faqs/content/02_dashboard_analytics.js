export default {
  key: "dashboard_analytics",
  icon: "dashboard",
  title: {
    en: "Dashboard & Analytics",
    vi: "Bảng điều khiển & Phân tích"
  },
  questions: [
    {
      slug: "dashboard-versus-analytics",
      question: {
        en: "What is the difference between Dashboard and Analytics?",
        vi: "Sự khác nhau giữa Bảng điều khiển và Phân tích là gì?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Dashboard is the morning briefing: what needs attention right now, with a fixed view of this month and the last 30 days. Analytics is the periodic review: choose a period and compare revenue, margin, customers, stock, and workforce with the period before. Dashboard links to Analytics for financial readers; Analytics does not replace the live operational numbers on the Dashboard.",
            vi: "Bảng điều khiển là bản tin buổi sáng: những gì cần chú ý ngay, với góc nhìn cố định của tháng này và 30 ngày gần nhất. Phân tích là buổi xem lại định kỳ: chọn một giai đoạn và so sánh doanh thu, lợi nhuận, khách hàng, tồn kho và nhân sự với giai đoạn trước. Bảng điều khiển có liên kết sang Phân tích cho người xem tài chính; Phân tích không thay thế các số vận hành trực tiếp trên Bảng điều khiển."
          }
        }
      ]
    },
    {
      slug: "dashboard-blocks",
      question: {
        en: "What does Dashboard show, and how do I hide blocks?",
        vi: "Bảng điều khiển hiển thị gì và làm sao ẩn các khối?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Dashboard has up to ten blocks: company details, key metrics, revenue and orders, sales channels, needs attention, recent orders, top customers, staff today, upcoming events, and the company wallet. Open Config, uncheck the blocks you do not need, and save; hidden blocks keep their settings and can be restored later. The block order is fixed, and financial blocks are hidden automatically from employees who cannot read invoices.",
            vi: "Bảng điều khiển có tối đa mười khối: thông tin công ty, chỉ số chính, doanh thu và đơn hàng, kênh bán, việc cần chú ý, đơn hàng gần đây, khách hàng hàng đầu, nhân sự hôm nay, sự kiện sắp tới và ví công ty. Mở Config, bỏ chọn các khối không cần rồi lưu; khối bị ẩn vẫn giữ cấu hình và có thể bật lại sau. Thứ tự khối là cố định, và khối tài chính tự ẩn với nhân viên không có quyền xem hóa đơn."
          }
        },
        {
          type: "links",
          items: [
            { label: { en: "Open Dashboard config", vi: "Mở cấu hình Bảng điều khiển" }, path: "company_dashboard_path" }
          ]
        }
      ]
    },
    {
      slug: "dashboard-fixed-period",
      question: {
        en: "Why is Dashboard fixed to “this month”?",
        vi: "Vì sao Bảng điều khiển cố định ở “tháng này”?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "The Dashboard is designed as a short morning briefing, so it always shows the current calendar month and a 30-day trend. Use Analytics when you need last month, the last six months, this year, or a comparison with the previous period. The month boundary follows the application time zone, so a company far from UTC can see the first or last day shift at the edge of a month.",
            vi: "Bảng điều khiển được thiết kế như bản tin buổi sáng ngắn, nên luôn hiển thị tháng dương lịch hiện tại và xu hướng 30 ngày. Dùng Phân tích khi cần tháng trước, sáu tháng gần nhất, năm nay hoặc so sánh với giai đoạn trước. Ranh giới tháng theo múi giờ của hệ thống, nên công ty ở múi giờ cách xa UTC có thể thấy ngày đầu hoặc ngày cuối bị lệch ở rìa tháng."
          }
        }
      ]
    },
    {
      slug: "dashboard-financial-blocks",
      question: {
        en: "Why do some employees not see financial blocks?",
        vi: "Vì sao một số nhân viên không thấy các khối tài chính?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Revenue, margin, top customers, trend charts, and the wallet require permission to read invoices. Employees without that permission still see the operational blocks: attention items, recent orders, staff, and upcoming events. Block visibility is company-wide, while the financial gate is per employee, so two people can open the same Dashboard and see different money blocks. Grant the invoice read policy if a role needs the financial view.",
            vi: "Doanh thu, lợi nhuận, khách hàng hàng đầu, biểu đồ xu hướng và ví yêu cầu quyền xem hóa đơn. Nhân viên không có quyền đó vẫn thấy các khối vận hành: việc cần chú ý, đơn hàng gần đây, nhân sự và sự kiện sắp tới. Việc bật/tắt khối là toàn công ty, còn cổng tài chính là theo từng nhân viên, nên hai người có thể mở cùng Bảng điều khiển và thấy các khối tiền khác nhau. Hãy cấp chính sách xem hóa đơn nếu vai trò cần góc nhìn tài chính."
          }
        }
      ]
    },
    {
      slug: "revenue-and-margin",
      question: {
        en: "How is revenue calculated, and why can gross margin be blank?",
        vi: "Doanh thu được tính thế nào và vì sao biên lợi nhuận có thể trống?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Revenue is the total of paid invoices in the selected period, calculated by the same shared revenue calculator used by Analytics and KPI. Gross margin subtracts tracked cost from that revenue, so it is only meaningful when product costs are filled in. The cost-coverage figure beside it shows how much of the revenue has a known cost; when coverage is low, the margin is blank rather than a misleading zero. Fill product costs to improve both numbers.",
            vi: "Doanh thu là tổng hóa đơn đã thanh toán trong giai đoạn đã chọn, được tính bằng cùng bộ tính doanh thu dùng cho Phân tích và KPI. Biên lợi nhuận lấy doanh thu trừ giá vốn đã theo dõi, nên chỉ có ý nghĩa khi giá vốn sản phẩm đã được nhập. Chỉ số độ phủ giá vốn bên cạnh cho biết bao nhiêu phần doanh thu đã có giá vốn; khi độ phủ thấp, biên lợi nhuận để trống thay vì hiển thị số 0 gây hiểu nhầm. Hãy nhập giá vốn sản phẩm để cải thiện cả hai chỉ số."
          }
        }
      ]
    },
    {
      slug: "analytics-periods-and-metrics",
      question: {
        en: "What periods, comparisons, and metrics does Analytics use?",
        vi: "Phân tích dùng những giai đoạn, so sánh và chỉ số nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Analytics offers this month, last month, the last six months, and this year. Every number is compared with the immediately previous period, not with the same period last year. The page covers key pillars, secondary metrics, revenue versus tracked cost, revenue mix by category and branch, top products and services, customer cohorts, inventory velocity, workforce hours, and top customers by lifetime value. Cohort retention is capped at six months, and there is no export, drill-down, or forecast yet.",
            vi: "Phân tích có tháng này, tháng trước, sáu tháng gần nhất và năm nay. Mọi con số được so với giai đoạn ngay trước đó, không phải cùng kỳ năm trước. Trang bao gồm các trụ cột chính, chỉ số phụ, doanh thu so với giá vốn, cơ cấu doanh thu theo danh mục và chi nhánh, sản phẩm/dịch vụ hàng đầu, nhóm khách hàng, tốc độ tồn kho, giờ nhân sự và khách hàng hàng đầu theo giá trị trọn đời. Tỷ lệ giữ chân nhóm khách hàng giới hạn ở sáu tháng, và chưa có xuất báo cáo, xem chi tiết hay dự báo."
          }
        }
      ]
    },
    {
      slug: "why-numbers-lag",
      question: {
        en: "Why don’t numbers update immediately?",
        vi: "Vì sao các con số không cập nhật ngay?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Dashboard data is cached for about five minutes, so a sale or stock change can take a few minutes to appear there. Operational consoles are different: Store Manager refreshes every 60 seconds, Reception every 20 seconds, and both have a manual refresh. Analytics is calculated when you open or change the period, so it reflects the moment of the request. If a number still looks wrong after a refresh, check the source page (orders, invoices, or stock) before treating it as a reporting bug.",
            vi: "Dữ liệu Bảng điều khiển được lưu đệm khoảng năm phút, nên một lần bán hoặc thay đổi tồn kho có thể mất vài phút mới hiện ở đó. Các màn hình vận hành thì khác: Store Manager làm mới mỗi 60 giây, Reception mỗi 20 giây, và cả hai đều có nút làm mới tay. Phân tích được tính khi bạn mở hoặc đổi giai đoạn, nên phản ánh thời điểm yêu cầu. Nếu sau khi làm mới mà số vẫn sai, hãy kiểm tra trang nguồn (đơn hàng, hóa đơn hoặc tồn kho) trước khi coi đó là lỗi báo cáo."
          }
        }
      ]
    }
  ]
}
