import Companies_LayoutController from "controllers/companies/layout_controller"
import ApexCharts from 'apexcharts'

export default class Companies_Branches_EmployeesController extends Companies_LayoutController {
  static targets = ["chartContainer"]
  connect() {
    super.connect()
    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        this.renderCharts()
        return true // Success! Stop polling.
      }
      return false // Layout isn't ready yet, keep waiting.
    })
  }
  renderCharts() {
    const options = {
      series: [{
        name: 'Employee Performance',
        data: [21, 22, 10, 28, 16, 21, 13, 30]
      }],
      chart: {
        height: 350,
        type: 'bar', // Column Chart
        events: {
          click: function(chart, w, e) {
            // console.log(chart, w, e)
          }
        }
      },
      colors: ['#008FFB', '#00E396', '#FEB019', '#FF4560', '#775DD0', '#546E7A', '#26a69a', '#D10CE8'],
      plotOptions: {
        bar: {
          columnWidth: '45%',
          distributed: true, // 2. THIS IS THE KEY FOR DISTRIBUTED COLORS
        }
      },
      dataLabels: {
        enabled: false
      },
      legend: {
        show: false
      },
      xaxis: {
        categories: [
          ['John', 'Doe'],
          ['Joe', 'Smith'],
          ['Jake', 'Williams'],
          'Amber',
          ['Peter', 'Brown'],
          ['Mary', 'Evans'],
          ['David', 'Wilson'],
          ['Lily', 'Roberts'], 
        ],
        labels: {
          style: {
            colors: ['#008FFB', '#00E396', '#FEB019', '#FF4560', '#775DD0', '#546E7A', '#26a69a', '#D10CE8'],
            fontSize: '12px'
          }
        }
      }
    };

    // Use Stimulus target instead of ID querySelector for stability
    const chart = new ApexCharts(this.chartContainerTarget, options);
    chart.render();
  }

  contentHTML() {
    // 3. Add the data-target to your HTML
    return `
      <div class="p-4 bg-white shadow rounded">
        <h3 class="mb-4 font-bold text-lg">Team Distribution Analytics</h3>
        <div data-${this.identifier}-target="chartContainer"></div>
      </div>
    `
  }
}
