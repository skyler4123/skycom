export default {
  key: "operations_access",
  icon: "apps",
  title: {
    en: "Operations & console access",
    vi: "Vận hành & quyền mở màn hình"
  },
  questions: [
    {
      slug: "what-are-operations",
      question: {
        en: "What are Operations, and why are there five?",
        vi: "Vận hành là gì và vì sao có năm loại?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Operations are full-screen working surfaces keyed by purpose, not by industry or job title: POS for taking money, Booking for reserving spaces, Inventory for warehouse stock, Reception for the front desk, and Store Manager for the branch day. A hotel and a clinic use the same five consoles; their categories, fields, locations, and permissions make the difference. That is why there is no separate “hotel mode” or “clinic mode” to configure.",
            vi: "Vận hành là các màn hình làm việc toàn màn hình theo mục đích, không theo ngành hay chức danh: POS để thu tiền, Booking để đặt không gian, Inventory để quản lý tồn kho, Reception cho lễ tân và Store Manager cho ngày bán hàng của chi nhánh. Khách sạn và phòng khám dùng cùng năm màn hình; danh mục, trường, địa điểm và phân quyền tạo nên khác biệt. Vì vậy không có “chế độ khách sạn” hay “chế độ phòng khám” riêng để cấu hình."
          }
        }
      ]
    },
    {
      slug: "operation-config-and-appointment",
      question: {
        en: "What is the difference between an operation, its config, and a location appointment?",
        vi: "Sự khác nhau giữa vận hành, cấu hình và lịch tại địa điểm là gì?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "An operation is the company-level definition of one console, such as POS. Its config is the company-wide settings, mainly the access roles. A branch or warehouse appointment switches that operation on at one location and can narrow the roles locally. The operation config is copied to each location when it is saved, so a location starts from the company settings and may then override them until the next company-wide save. Local roles can only narrow access, never widen it.",
            vi: "Vận hành là định nghĩa cấp công ty của một màn hình, ví dụ POS. Cấu hình của nó là cài đặt toàn công ty, chủ yếu là vai trò được truy cập. Lịch tại chi nhánh hoặc kho bật vận hành đó ở một địa điểm và có thể thu hẹp vai trò tại chỗ. Cấu hình vận hành được sao chép vào từng địa điểm khi lưu, nên địa điểm bắt đầu từ cài đặt công ty và có thể ghi đè cho đến lần lưu toàn công ty tiếp theo. Vai trò tại địa điểm chỉ có thể thu hẹp quyền, không thể mở rộng."
          }
        }
      ]
    },
    {
      slug: "new-location-operations",
      question: {
        en: "Which operations does a new branch or warehouse get?",
        vi: "Chi nhánh hoặc kho mới nhận những vận hành nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Every company receives the full catalog. A new branch gets appointments for the branch-scoped operations (POS, Booking, Reception, and Store Manager), and a new warehouse gets the warehouse-scoped Inventory operation. All appointments start active, so a location can work immediately; disable the ones that location does not use. If a location is missing a console, check the appointment status and the role gate before assuming the operation was never created.",
            vi: "Mọi công ty nhận đủ danh mục. Chi nhánh mới nhận lịch cho các vận hành theo chi nhánh (POS, Booking, Reception và Store Manager), kho mới nhận vận hành Inventory theo kho. Tất cả lịch bắt đầu ở trạng thái hoạt động, nên địa điểm dùng được ngay; hãy tắt những vận hành địa điểm đó không dùng. Nếu một địa điểm thiếu màn hình, kiểm tra trạng thái lịch và cổng vai trò trước khi cho rằng vận hành chưa được tạo."
          }
        }
      ]
    },
    {
      slug: "turn-off-operation",
      question: {
        en: "How do I turn an operation off at one location?",
        vi: "Làm sao tắt một vận hành tại một địa điểm?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Open Operations, find the row for that operation and location, and edit the appointment. Set the status to Inactive and save. The launch icon becomes disabled with a reason, and nobody can open that console at that location until it is active again. This is per location by design; turning an operation off for the whole company means repeating the change for each appointment.",
            vi: "Mở Vận hành, tìm dòng của vận hành và địa điểm đó, rồi sửa lịch. Đặt trạng thái thành Ngừng hoạt động và lưu. Nút mở sẽ bị vô hiệu kèm lý do, và không ai mở được màn hình đó tại địa điểm cho đến khi bật lại. Việc tắt theo từng địa điểm là có chủ đích; tắt cho toàn công ty nghĩa là lặp lại thay đổi cho từng lịch."
          }
        }
      ]
    },
    {
      slug: "control-console-roles",
      question: {
        en: "How do I control which roles can open a console?",
        vi: "Làm sao kiểm soát vai trò nào được mở một màn hình?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Set the company-wide roles on the operation config, then narrow them on each location appointment if needed. An empty role list at the operation level means all company roles; at the location level, an empty list inherits the operation roles. The effective roles are the intersection of both levels, and launching also requires the normal permission check for the operation. If someone still cannot open a console, check the operation appointment status and their role, not only the role list.",
            vi: "Đặt vai trò toàn công ty trên cấu hình vận hành, sau đó thu hẹp trên từng lịch địa điểm nếu cần. Danh sách vai trò trống ở cấp vận hành nghĩa là mọi vai trò công ty; ở cấp địa điểm, danh sách trống sẽ kế thừa vai trò của vận hành. Vai trò hiệu lực là giao của cả hai cấp, và việc mở còn cần kiểm tra quyền thông thường cho vận hành. Nếu ai đó vẫn không mở được, hãy kiểm tra trạng thái lịch và vai trò của họ, không chỉ danh sách vai trò."
          }
        }
      ]
    },
    {
      slug: "save-company-operation-config",
      question: {
        en: "What happens when I save the company-wide config?",
        vi: "Điều gì xảy ra khi lưu cấu hình toàn công ty?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Saving the operation config copies its settings — mainly the access roles — onto every branch and warehouse location. Any local override is replaced by the company value, and the edit page warns you before you save. The locations then keep the new company baseline until someone edits one again. If you need a location-specific exception, save the company config first, then edit that location.",
            vi: "Lưu cấu hình vận hành sẽ sao chép cài đặt của nó — chủ yếu là vai trò truy cập — vào mọi địa điểm chi nhánh và kho. Mọi ghi đè tại địa điểm sẽ bị thay bằng giá trị công ty, và trang sửa có cảnh báo trước khi lưu. Các địa điểm sau đó giữ mức nền mới của công ty cho đến khi có người sửa lại. Nếu cần ngoại lệ theo địa điểm, hãy lưu cấu hình công ty trước, rồi sửa địa điểm đó."
          }
        }
      ]
    },
    {
      slug: "add-operation-type",
      status: "planned",
      question: {
        en: "Why can’t I add a new operation type, and why is a console missing?",
        vi: "Vì sao không thể thêm loại vận hành mới và vì sao thiếu một màn hình?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "The catalog is fixed at five operation types, and there is no create action in the UI. Adding one would require new server and screen development, pre-created assignments for every existing branch or warehouse, and a role gate — not just a new row. A console can appear missing for a simpler reason: the location assignment is inactive, the employee's role is not allowed, or the assignment was never created for that location. The Operations list and the launch tooltip distinguish those cases.",
            vi: "Danh mục cố định năm loại vận hành và không có thao tác tạo trên giao diện. Thêm loại mới sẽ cần phát triển máy chủ và màn hình mới, tạo sẵn phân công cho mọi chi nhánh/kho hiện có, và cổng vai trò — không chỉ một dòng mới. Một màn hình có thể trông như thiếu vì lý do đơn giản hơn: phân công tại địa điểm đang tắt, vai trò nhân viên không được phép, hoặc phân công chưa từng được tạo cho địa điểm đó. Danh sách Vận hành và chú thích nút mở phân biệt các trường hợp này."
          }
        }
      ]
    }
  ]
}
