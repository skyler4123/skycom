export default {
  key: "exams",
  icon: "quiz",
  title: {
    en: "Exams",
    vi: "Bài kiểm tra"
  },
  questions: [
    {
      slug: "question-bank-versus-exam",
      question: {
        en: "What is the Question Bank vs an Exam?",
        vi: "Ngân hàng câu hỏi và Bài kiểm tra khác nhau thế nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "The Question Bank is the reusable pool: each question has a type, points, optional choices, and a category such as Safety or Customer Service. An Exam is a scored definition built from selected questions, with a duration, pass mark, attempt limit, and shuffle setting. You can reuse one question in several exams, and editing the bank is separate from publishing an exam. Exams and questions are company-scoped and web-only.",
            vi: "Ngân hàng câu hỏi là kho dùng lại: mỗi câu có loại, điểm, lựa chọn tùy chọn và danh mục như An toàn hoặc Chăm sóc khách hàng. Bài kiểm tra là định nghĩa có điểm được xây từ các câu đã chọn, với thời lượng, điểm đạt, giới hạn số lần và tùy chọn xáo trộn. Một câu có thể dùng lại trong nhiều bài, và sửa ngân hàng tách khỏi việc xuất bản bài. Bài kiểm tra và câu hỏi thuộc công ty và chỉ có trên web."
          }
        }
      ]
    },
    {
      slug: "exam-question-types",
      question: {
        en: "Which question types are supported?",
        vi: "Hỗ trợ những loại câu hỏi nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Three types: single choice, true/false, and text. Single choice needs at least two options and exactly one correct option; true/false has exactly two options with one correct; text has no options and may have a model answer used for manual grading. Multi-select is not exposed in the UI even though the schema can store selected options. Points are set per question and snapshotted when an attempt starts.",
            vi: "Ba loại: một lựa chọn, đúng/sai và trả lời văn bản. Một lựa chọn cần ít nhất hai phương án và đúng một phương án; đúng/sai có đúng hai phương án với một đáp án đúng; văn bản không có phương án và có thể có đáp án mẫu để chấm tay. Giao diện chưa mở loại nhiều lựa chọn dù lược đồ có thể lưu các phương án đã chọn. Điểm được đặt cho từng câu và sao lưu khi lượt làm bắt đầu."
          }
        }
      ]
    },
    {
      slug: "build-publish-assign-exam",
      question: {
        en: "How do I build, publish, and assign an exam?",
        vi: "Làm sao tạo, xuất bản và giao bài kiểm tra?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Create the exam, set its duration, pass mark, attempt limit, and shuffle option, then add questions from the bank in the order you want. Save it as a draft while you work. Publish when the question set is complete; only a published exam can be assigned. Assignment creates an employee exam row for each selected employee, and the employee starts it from My Exams.",
            vi: "Tạo bài, đặt thời lượng, điểm đạt, giới hạn số lần và tùy chọn xáo trộn, rồi thêm câu từ ngân hàng theo thứ tự mong muốn. Lưu nháp trong lúc làm. Xuất bản khi bộ câu hỏi đã đủ; chỉ bài đã xuất bản mới giao được. Giao bài tạo một dòng bài kiểm tra cho từng nhân viên được chọn, và nhân viên bắt đầu từ My Exams."
          }
        },
        {
          type: "links",
          items: [
            { label: { en: "Open Exams", vi: "Mở Bài kiểm tra" }, path: "company_exams_path" },
            { label: { en: "Open Question Bank", vi: "Mở Ngân hàng câu hỏi" }, path: "company_questions_path" }
          ]
        }
      ]
    },
    {
      slug: "cannot-publish-assign-exam",
      question: {
        en: "Why can’t I publish or assign an exam?",
        vi: "Vì sao không thể xuất bản hoặc giao bài kiểm tra?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "An exam cannot be published until it has at least one question; the publish action fails rather than creating an empty assessment. Assignment requires the exam to be published, and an archived exam cannot be assigned or started, though attempts already in progress may finish. If the exam looks published but assignment is unavailable, check its status and whether the employee already has an active attempt.",
            vi: "Bài kiểm tra không thể xuất bản khi chưa có ít nhất một câu hỏi; thao tác xuất bản sẽ thất bại thay vì tạo bài rỗng. Giao bài yêu cầu bài đã xuất bản, và bài đã lưu trữ không giao hoặc bắt đầu được, dù lượt đang làm vẫn có thể hoàn tất. Nếu bài trông như đã xuất bản mà không giao được, hãy kiểm tra trạng thái và việc nhân viên đã có lượt đang làm hay chưa."
          }
        }
      ]
    },
    {
      slug: "exam-attempts-deadlines",
      question: {
        en: "How do attempts, deadlines, and retakes work?",
        vi: "Lượt làm, hạn chót và làm lại hoạt động thế nào?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "An employee has at most one active attempt per exam. Starting uses the assigned row or creates the next attempt when attempts remain; a null attempt limit means unlimited. The server stores the deadline, the timed page keeps it across refreshes, and a 30-second grace period absorbs network latency before an overdue attempt is expired. Retakes are employee-initiated from My Exams after a graded or expired attempt, if attempts remain; a manager can raise the limit.",
            vi: "Mỗi nhân viên có tối đa một lượt đang làm cho mỗi bài. Bắt đầu sẽ dùng dòng đã giao hoặc tạo lượt tiếp theo khi còn lượt; giới hạn rỗng nghĩa là không giới hạn. Máy chủ lưu hạn chót, trang làm bài giữ hạn qua lần tải lại, và 30 giây ân hạn bù độ trễ mạng trước khi lượt quá hạn bị đánh dấu hết hạn. Nhân viên tự làm lại từ My Exams sau lượt đã chấm hoặc hết hạn nếu còn lượt; quản lý có thể tăng giới hạn."
          }
        }
      ]
    },
    {
      slug: "exam-scoring-grading",
      question: {
        en: "How is an exam scored, and who grades text answers?",
        vi: "Bài kiểm tra được chấm thế nào và ai chấm câu trả lời văn bản?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Objective answers earn full points or zero; text answers are graded manually from zero to the question's points, and a text answer counts as correct only at full points. The score is earned points divided by total points, multiplied by 100, and the exam is passed when the score reaches the pass mark. The points possible are snapshotted when the attempt starts, so later edits to the bank do not change a running or graded attempt.",
            vi: "Câu khách quan được điểm tối đa hoặc 0; câu văn bản được chấm tay từ 0 đến điểm của câu, và chỉ được coi là đúng khi đạt điểm tối đa. Điểm bài là điểm đạt được chia tổng điểm, nhân 100, và bài được coi là đạt khi điểm chạm mức đạt. Điểm tối đa được sao lưu khi lượt làm bắt đầu, nên sửa ngân hàng sau đó không làm đổi lượt đang làm hoặc đã chấm."
          }
        }
      ]
    },
    {
      slug: "exam-summary",
      question: {
        en: "What does the exam summary count?",
        vi: "Tóm tắt bài kiểm tra đếm những gì?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "The summary is per employee, not per attempt: an employee who failed then passed counts once as passed and zero as failed, and the best graded score feeds the average. It also shows pending review, expired attempts, and per-question statistics from graded answers only. Skycom keeps one summary per exam, refreshed by a background process after assignment, start, submit, grade, or expiry, and by the manual Refresh Summary action.",
            vi: "Tóm tắt tính theo nhân viên, không theo lượt: người từng trượt rồi đạt được tính một lần là đạt và 0 lần trượt, và điểm đã chấm cao nhất dùng cho trung bình. Tóm tắt cũng hiện số đang chờ chấm, lượt hết hạn và thống kê từng câu chỉ từ các câu đã chấm. Skycom giữ một bản tóm tắt cho mỗi bài, làm mới bởi tiến trình nền sau khi giao, bắt đầu, gửi, chấm hoặc hết hạn, và bởi thao tác làm mới tay."
          }
        }
      ]
    },
    {
      slug: "exam-edits-and-past-attempts",
      question: {
        en: "Do question edits change past attempts?",
        vi: "Sửa câu hỏi có làm đổi các lượt đã làm không?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "No. At attempt start, Skycom snapshots each question and its options into the answer row and stores the displayed option order. Later edits to the question bank never rewrite a running or completed attempt, which is why a result can look different from the current question text. Choice order may be shuffled per attempt for single choice; true/false is never shuffled.",
            vi: "Không. Khi lượt làm bắt đầu, Skycom sao lưu từng câu và các phương án vào dòng trả lời, đồng thời lưu thứ tự phương án đã hiển thị. Sửa ngân hàng câu hỏi sau đó không viết lại lượt đang làm hoặc đã hoàn tất, nên kết quả có thể khác văn bản câu hỏi hiện tại. Thứ tự phương án có thể được xáo cho câu một lựa chọn; đúng/sai không bao giờ xáo."
          }
        }
      ]
    },
    {
      slug: "exam-mobile",
      status: "planned",
      question: {
        en: "Are exams available on mobile?",
        vi: "Bài kiểm tra có trên di động không?"
      },
      answer: [
        {
          type: "p",
          text: {
            en: "Not yet. Exams, the Question Bank, My Exams, and the timed attempt page are web-only; the Android shell has no exam tab or route. Employees must use the web app to take an assessment. Mobile exam pages are tracked as a follow-up, and no notification is sent when an exam is assigned.",
            vi: "Chưa hỗ trợ. Bài kiểm tra, Ngân hàng câu hỏi, My Exams và trang làm bài có giờ đều chỉ có trên web; ứng dụng Android không có tab hay route bài kiểm tra. Nhân viên phải dùng web để làm bài. Trang bài kiểm tra trên di động đang được theo dõi như việc tiếp theo, và hiện không gửi thông báo khi giao bài."
          }
        }
      ]
    }
  ]
}
