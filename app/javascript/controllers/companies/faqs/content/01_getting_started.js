export default {
  key: "getting_started",
  icon: "rocket_launch",
  title: {
    en: "Getting started & company setup",
    vi: "Bắt đầu & thiết lập công ty"
  },
  questions: [
    {
      slug: "what-is-skycom",
      question: {
        en: "What is Skycom, and what can one company workspace manage?",
        vi: "Skycom là gì và một không gian công ty quản lý được những gì?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Skycom is a multi-tenant business management platform. One company workspace holds selling, stock, people, operations, money, and settings, while branches and warehouses are locations inside that company. Every record belongs to exactly one company, so another company never sees your products, customers, orders, or employees. The same platform serves retail, hospitality, clinics, schools, and offices; what changes is your categories, custom fields, locations, and permissions — not the core screens.",
            vi: "Skycom là nền tảng quản trị doanh nghiệp đa công ty (multi-tenant). Mỗi không gian công ty quản lý bán hàng, tồn kho, nhân sự, vận hành, tiền và cấu hình; chi nhánh và kho chỉ là các địa điểm bên trong công ty. Mọi bản ghi thuộc đúng một công ty, nên công ty khác không thể thấy sản phẩm, khách hàng, đơn hàng hay nhân viên của bạn. Cùng một nền tảng phục vụ bán lẻ, khách sạn, phòng khám, trường học và văn phòng; điều khác nhau là danh mục, trường tùy chỉnh, địa điểm và phân quyền — không phải các màn hình cốt lõi."
          }
        },
        {
          type: "note",
          text: {
            en: "A company is the data boundary. Branches and warehouses are locations inside it, not separate tenants.",
            vi: "Công ty là ranh giới dữ liệu. Chi nhánh và kho là các địa điểm bên trong công ty, không phải các tenant riêng."
          }
        }
      ]
    },
    {
      slug: "create-account-and-company",
      question: {
        en: "How do I create an account and set up my company?",
        vi: "Làm thế nào để tạo tài khoản và thiết lập công ty?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Create your user account from the sign-up page with an email address and password. The account is the login, not the company: once you are signed in, create the company if your account is allowed to do so, or open the company you were invited to. When the company is created, Skycom creates the owner employee, roles, categories, policies, operations, and a promotional credit balance so the workspace is usable immediately.",
            vi: "Tạo tài khoản người dùng từ trang đăng ký bằng email và mật khẩu. Tài khoản là thông tin đăng nhập, không phải công ty: sau khi đăng nhập, hãy tạo công ty nếu tài khoản của bạn được phép, hoặc mở công ty mà bạn được mời. Khi công ty được tạo, Skycom tự tạo nhân viên Owner, vai trò, danh mục, chính sách, vận hành và số dư tín dụng khuyến mãi để không gian làm việc dùng được ngay."
          }
        },
        {
          type: "steps",
          items: [
            { en: "Sign up with your email address and a password.", vi: "Đăng ký bằng email và mật khẩu." },
            { en: "Create the company and enter its name, country, currency, and timezone.", vi: "Tạo công ty và nhập tên, quốc gia, tiền tệ và múi giờ." },
            { en: "Open Settings → Company to add the logo and contact details.", vi: "Mở Settings → Company để thêm logo và thông tin liên hệ." },
            { en: "Add your first branch, then invite or create employees with roles.", vi: "Thêm chi nhánh đầu tiên, sau đó mời hoặc tạo nhân viên với vai trò." }
          ]
        }
      ]
    },
    {
      slug: "what-is-created-automatically",
      question: {
        en: "What does Skycom create automatically when a company is created?",
        vi: "Skycom tự tạo những gì khi một công ty được tạo?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "A new company starts with the records it needs to be usable: an Owner employee and Owner role, the standard roles and policies, categories with their dynamic property mappings and table layouts, the five operations, payment methods for the company's country, and a company wallet with a promotional credit balance. Each branch or warehouse you add receives its own operation appointments, and each branch receives payment-method appointments. You do not need to build these by hand before your first sale.",
            vi: "Công ty mới được tạo sẵn các bản ghi cần thiết để dùng được: nhân viên Owner và vai trò Owner, các vai trò và chính sách chuẩn, danh mục kèm ánh xạ thuộc tính động và bố cục bảng, năm vận hành, phương thức thanh toán theo quốc gia và ví công ty với số dư tín dụng khuyến mãi. Mỗi chi nhánh hoặc kho bạn thêm sẽ nhận các lịch vận hành riêng, và mỗi chi nhánh nhận các phương thức thanh toán riêng. Bạn không cần tạo tay những thứ này trước lần bán đầu tiên."
          }
        },
        {
          type: "note",
          text: {
            en: "Automatic records are a starting point, not a finished configuration. Review roles, categories, and payment methods before staff sign in.",
            vi: "Các bản ghi tự động chỉ là điểm khởi đầu, không phải cấu hình hoàn chỉnh. Hãy xem lại vai trò, danh mục và phương thức thanh toán trước khi nhân viên đăng nhập."
          }
        },
        {
          type: "links",
          items: [
            { label: { en: "Open Operations", vi: "Mở Vận hành" }, path: "company_operations_path" },
            { label: { en: "Open Roles", vi: "Mở Vai trò" }, path: "company_roles_path" }
          ]
        }
      ]
    },
    {
      slug: "user-versus-employee",
      question: {
        en: "What is the difference between a User and an Employee?",
        vi: "Sự khác nhau giữa User và Nhân viên là gì?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "A User is a login identity: an email address, password, session, and access to one or more companies. An Employee is a company record: the person's name, role, branch, category, shifts, attendance, payroll, and permissions inside that company. A User can be linked to an Employee, but an Employee can exist without a login — useful for staff who never sign in. If the same person works for two companies, they can have one User and one Employee record in each company.",
            vi: "User là danh tính đăng nhập: email, mật khẩu, phiên làm việc và quyền truy cập một hoặc nhiều công ty. Nhân viên là bản ghi trong công ty: họ tên, vai trò, chi nhánh, danh mục, ca làm, chấm công, bảng lương và quyền bên trong công ty đó. User có thể được liên kết với Nhân viên, nhưng Nhân viên có thể tồn tại mà không cần đăng nhập — hữu ích cho nhân sự không bao giờ đăng nhập. Nếu cùng một người làm cho hai công ty, họ có một User và một bản ghi Nhân viên ở mỗi công ty."
          }
        },
        {
          type: "note",
          text: {
            en: "Removing a login does not delete the employee's history. Removing an employee is a company record change and affects their shifts, attendance, and payroll access.",
            vi: "Xóa đăng nhập không xóa lịch sử của nhân viên. Xóa nhân viên là thay đổi bản ghi công ty và ảnh hưởng đến ca làm, chấm công và quyền xem bảng lương của họ."
          }
        }
      ]
    },
    {
      slug: "owner-role-and-transfer",
      status: "planned",
      question: {
        en: "What is the Owner role, and can ownership be transferred?",
        vi: "Vai trò Owner là gì và có thể chuyển quyền sở hữu không?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "The Owner role is the company's protected top-level role. The owner bypasses permission checks, cannot be renamed or deleted through the UI, and is the only role that can manage certain company settings. Ownership transfer is not available yet: there is no screen to move the Owner role to another employee, and the owner record is created with the company. Until that changes, contact Skycom support if the owner must change; this answer will be updated when transfer ships.",
            vi: "Vai trò Owner là vai trò cấp cao nhất được bảo vệ của công ty. Owner bỏ qua kiểm tra quyền, không thể đổi tên hoặc xóa qua giao diện, và là vai trò duy nhất quản lý được một số cài đặt công ty. Hiện chưa hỗ trợ chuyển quyền sở hữu: không có màn hình chuyển vai trò Owner sang nhân viên khác, và bản ghi owner được tạo cùng công ty. Trong thời gian đó, hãy liên hệ hỗ trợ Skycom nếu cần đổi owner; câu trả lời này sẽ được cập nhật khi tính năng chuyển quyền ra mắt."
          }
        }
      ]
    },
    {
      slug: "branch-versus-warehouse",
      question: {
        en: "What is the difference between a branch and a warehouse?",
        vi: "Sự khác nhau giữa chi nhánh và kho là gì?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "A branch is a selling or service location: the shop, restaurant, clinic, hotel front desk, or office where customers are served. It owns employees, orders, payment methods, facilities, and branch-scoped operations such as POS and Booking. A warehouse is a stock-holding location: it owns stock rows and every import, export, transfer, adjustment, and cycle count. A branch can have one or more warehouses, and stock always belongs to a warehouse — never directly to a branch. This is why a branch can sell a product while the quantity lives in a warehouse ledger.",
            vi: "Chi nhánh là địa điểm bán hàng hoặc phục vụ: cửa hàng, nhà hàng, phòng khám, quầy lễ tân khách sạn hoặc văn phòng nơi tiếp khách. Chi nhánh sở hữu nhân viên, đơn hàng, phương thức thanh toán, cơ sở vật chất và các vận hành theo chi nhánh như POS và Booking. Kho là địa điểm giữ tồn kho: kho sở hữu các dòng tồn và mọi phiếu nhập, xuất, chuyển, điều chỉnh và kiểm kê. Một chi nhánh có thể có một hoặc nhiều kho, và tồn kho luôn thuộc về kho — không bao giờ thuộc trực tiếp chi nhánh. Vì vậy chi nhánh có thể bán sản phẩm trong khi số lượng nằm trong sổ kho."
          }
        }
      ]
    },
    {
      slug: "recommended-setup-order",
      question: {
        en: "What is the recommended setup order for a new company?",
        vi: "Thứ tự thiết lập đề xuất cho công ty mới là gì?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Use this order to avoid rework. Every step can be changed later, but doing the structure first means you do not have to re-enter products, stock, or employees after the layout changes.",
            vi: "Hãy dùng thứ tự này để tránh làm lại. Mọi bước đều có thể thay đổi sau, nhưng làm cấu trúc trước giúp bạn không phải nhập lại sản phẩm, tồn kho hay nhân viên khi bố cục thay đổi."
          }
        },
        {
          type: "steps",
          items: [
            { en: "Company details: name, country, currency, timezone, logo, and contact information.", vi: "Thông tin công ty: tên, quốc gia, tiền tệ, múi giờ, logo và thông tin liên hệ." },
            { en: "Locations: create branches first, then the warehouses that hold their stock.", vi: "Địa điểm: tạo chi nhánh trước, sau đó tạo các kho giữ tồn." },
            { en: "People: departments and employee groups, then employees and their roles.", vi: "Nhân sự: phòng ban và nhóm nhân viên, sau đó nhân viên và vai trò." },
            { en: "Permissions: review roles and policies before staff sign in.", vi: "Phân quyền: xem lại vai trò và chính sách trước khi nhân viên đăng nhập." },
            { en: "Catalog: categories and dynamic fields, then products, services, and suppliers.", vi: "Danh mục: danh mục và trường động, sau đó sản phẩm, dịch vụ và nhà cung cấp." },
            { en: "Stock: open stock rows and receive the opening quantities.", vi: "Tồn kho: mở các dòng tồn và nhập số lượng ban đầu." },
            { en: "Money: tax configuration, payment methods, and discounts.", vi: "Tiền: cấu hình thuế, phương thức thanh toán và giảm giá." },
            { en: "Operations: activate the consoles each location needs and choose their roles.", vi: "Vận hành: bật các màn hình từng địa điểm cần và chọn vai trò được dùng." },
            { en: "Test: sell one product, take one payment, and print one receipt.", vi: "Kiểm tra: bán một sản phẩm, thu một khoản thanh toán và in một biên lai." }
          ]
        }
      ]
    },
    {
      slug: "roles-policies-permissions",
      question: {
        en: "How do roles, policies, and permissions decide what I can see?",
        vi: "Vai trò, chính sách và quyền quyết định tôi thấy được gì như thế nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "A role is a named bundle of policies assigned to an employee. A policy grants one action on one resource — for example, 'read Products' or 'update Orders' — and may carry tag conditions that narrow it to records with a specific tag. Permissions are the effective rights produced by the employee's roles; every company request is checked against them, and the Owner bypasses the check. Inactive policy appointments do not grant access, and permission changes are recorded in Permission Logs. If a page is missing for someone, start by checking their role and the policy's active state, not by creating a new role.",
            vi: "Vai trò là một nhóm chính sách được gán cho nhân viên. Mỗi chính sách cấp một hành động trên một tài nguyên — ví dụ 'xem Sản phẩm' hoặc 'sửa Đơn hàng' — và có thể kèm điều kiện thẻ để giới hạn cho bản ghi có thẻ cụ thể. Quyền là các quyền hiệu lực do vai trò của nhân viên tạo ra; mọi yêu cầu trong công ty đều được kiểm tra theo đó, và Owner bỏ qua kiểm tra. Các liên kết chính sách không hoạt động sẽ không cấp quyền, và thay đổi quyền được ghi trong Nhật ký quyền. Nếu ai đó thiếu một trang, hãy kiểm tra vai trò và trạng thái hoạt động của chính sách trước, đừng tạo vai trò mới ngay."
          }
        },
        {
          type: "links",
          items: [
            { label: { en: "Open Permissions", vi: "Mở Phân quyền" }, path: "company_permissions_path" },
            { label: { en: "Open Permission Logs", vi: "Mở Nhật ký quyền" }, path: "company_permission_logs_path" }
          ]
        }
      ]
    }
  ]
}
