# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "@hotwired--stimulus.js" # @3.2.2
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "sweetalert2" # @11.26.3
pin "dayjs" # @1.11.19
pin "stimulus-use" # @0.52.3
pin "apexcharts" # @5.3.6
pin "tabulator" # @0.2.40
pin "best-globals" # @0.10.34
pin "buffer" # @2.1.0
pin "codenautas-xlsx" # @0.11.12
pin "crypto" # @2.1.0
pin "fs" # @2.1.0
pin "js-to-html" # @1.0.11
pin "like-ar" # @0.2.19
pin "process" # @2.1.0
pin "stream" # @2.1.0
