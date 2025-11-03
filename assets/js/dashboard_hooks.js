// Dashboard Chart.js Hooks for Phoenix LiveView
import Chart from 'chart.js/auto';

export const IncomeExpenseChart = {
  mounted() {
    const ctx = this.el.getContext('2d');
    const chartData = JSON.parse(this.el.dataset.chartData);
    this.chart = new Chart(ctx, {
      type: 'line',
      data: chartData,
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 300 },
        plugins: {
          legend: { position: 'top', display: true },
          title: { display: false },
          tooltip: {
            callbacks: {
              label: function(context) {
                const val = context.parsed.y ?? context.parsed;
                return context.dataset.label + ': $' + val.toLocaleString();
              }
            }
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            ticks: { callback: function(value) {
              return '$' + value.toLocaleString();
            }}
          }
        },
        elements: { point: { radius: 4, hoverRadius: 7 }},
        interaction: { intersect: false, mode: 'index' }
      }
    });
  },
  updated() {
    const chartData = JSON.parse(this.el.dataset.chartData);
    this.chart.data = chartData;
    this.chart.update('none');

    // Force a proper resize after data update
    setTimeout(() => {
      if (this.chart) {
        this.chart.resize();
      }
    }, 50);
  },
  destroyed() {
    if (this.chart) {
      this.chart.destroy();
    }
  }
};

export const MonthlyChart = {
  mounted() {
    const ctx = this.el.getContext('2d');
    const chartData = JSON.parse(this.el.dataset.chartData);
    this.chart = new Chart(ctx, {
      type: 'bar',
      data: chartData,
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 300 },
        plugins: {
          legend: { position: 'top', display: true },
          title: { display: false },
          tooltip: {
            callbacks: {
              label: function(context) {
                const val = context.parsed.y ?? context.parsed;
                return context.dataset.label + ': $' + val.toLocaleString();
              }
            }
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            ticks: { callback: function(value) {
              return '$' + value.toLocaleString();
            }}
          }
        }
      }
    });
  },
  updated() {
    const chartData = JSON.parse(this.el.dataset.chartData);
    this.chart.data = chartData;
    this.chart.update('none');

    // Force a proper resize after data update
    setTimeout(() => {
      if (this.chart) {
        this.chart.resize();
      }
    }, 50);
  },
  destroyed() {
    if (this.chart) {
      this.chart.destroy();
    }
  }
};

export const RatioChart = {
  mounted() {
    const ctx = this.el.getContext('2d');
    const chartData = JSON.parse(this.el.dataset.chartData);
    this.chart = new Chart(ctx, {
      type: 'pie',
      data: chartData,
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 300 },
        plugins: {
          legend: { position: 'top', display: true },
          title: { display: false },
          tooltip: {
            callbacks: {
              label: function(context) {
                const val = context.parsed ?? context.parsed;
                return context.label + ': $' + val.toLocaleString();
              }
            }
          }
        }
      }
    });
  },
  updated() {
    const chartData = JSON.parse(this.el.dataset.chartData);
    this.chart.data = chartData;
    this.chart.update('none');

    // Force a proper resize after data update
    setTimeout(() => {
      if (this.chart) {
        this.chart.resize();
      }
    }, 50);
  },
  destroyed() {
    if (this.chart) {
      this.chart.destroy();
    }
  }
};

export const CumulativeChart = {
  mounted() {
    const ctx = this.el.getContext('2d');
    const chartData = JSON.parse(this.el.dataset.chartData);
    this.chart = new Chart(ctx, {
      type: 'line',
      data: chartData,
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 300 },
        plugins: {
          legend: { position: 'top', display: true },
          title: { display: false },
          tooltip: {
            callbacks: {
              label: function(context) {
                const val = context.parsed.y ?? context.parsed;
                return context.dataset.label + ': $' + val.toLocaleString();
              }
            }
          }
        },
        scales: {
          y: {
            ticks: { callback: function(value) {
              return '$' + value.toLocaleString();
            }}
          }
        },
        elements: { point: { radius: 4, hoverRadius: 7 }},
        interaction: { intersect: false, mode: 'index' }
      }
    });
  },
  updated() {
    const chartData = JSON.parse(this.el.dataset.chartData);
    this.chart.data = chartData;
    this.chart.update('none');

    // Force a proper resize after data update
    setTimeout(() => {
      if (this.chart) {
        this.chart.resize();
      }
    }, 50);
  },
  destroyed() {
    if (this.chart) {
      this.chart.destroy();
    }
  }
};

export const NetProfitChart = {
  mounted() {
    const ctx = this.el.getContext('2d');
    const chartData = JSON.parse(this.el.dataset.chartData);
    this.chart = new Chart(ctx, {
      type: 'line',
      data: chartData,
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 300 },
        plugins: {
          legend: { position: 'top', display: true },
          title: { display: false },
          tooltip: {
            callbacks: {
              label: function(context) {
                const val = context.parsed.y ?? context.parsed;
                return context.dataset.label + ': $' + val.toLocaleString();
              }
            }
          }
        },
        scales: {
          y: {
            ticks: { callback: function(value) {
              return '$' + value.toLocaleString();
            }}
          }
        },
        elements: { point: { radius: 4, hoverRadius: 7 }},
        interaction: { intersect: false, mode: 'index' }
      }
    });
  },
  updated() {
    const chartData = JSON.parse(this.el.dataset.chartData);
    this.chart.data = chartData;
    this.chart.update('none');

    // Force a proper resize after data update
    setTimeout(() => {
      if (this.chart) {
        this.chart.resize();
      }
    }, 50);
  },
  destroyed() {
    if (this.chart) {
      this.chart.destroy();
    }
  }
};

export const InvestmentsComparisonChart = {
  mounted() {
    setTimeout(() => {
      this.initializeChart();
    }, 50);
  },

  initializeChart() {
    const ctx = this.el.getContext('2d');
    const chartData = JSON.parse(this.el.dataset.chartData);

    this.chart = new Chart(ctx, {
      type: 'line',
      data: chartData,
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'top',
            display: true
          },
          title: {
            display: true,
            text: 'Investment Performance Comparison'
          },
          tooltip: {
            mode: 'index',
            intersect: false,
            callbacks: {
              label: function(context) {
                const val = context.parsed.y ?? context.parsed;
                return context.dataset.label + ': $' + val.toLocaleString();
              }
            }
          }
        },
        scales: {
          x: {
            display: true,
            title: {
              display: true,
              text: 'Date'
            }
          },
          y: {
            display: true,
            title: {
              display: true,
              text: 'Value ($)'
            },
            ticks: {
              callback: function(value) {
                return '$' + value.toLocaleString();
              }
            }
          }
        },
        elements: {
          point: {
            radius: 4,
            hoverRadius: 7
          },
          line: {
            tension: 0.2
          }
        },
        interaction: {
          mode: 'nearest',
          axis: 'x',
          intersect: false
        }
      }
    });

    setTimeout(() => {
      if (this.chart) {
        this.chart.resize();
      }
    }, 100);
  },

  updated() {
    if (this.chart) {
      const chartData = JSON.parse(this.el.dataset.chartData);
      this.chart.data = chartData;
      this.chart.update('none');

      setTimeout(() => {
        if (this.chart) {
          this.chart.resize();
        }
      }, 50);
    } else {
      this.initializeChart();
    }
  },

  destroyed() {
    if (this.chart) {
      this.chart.destroy();
    }
  }
};

export const RoiChart = {
  mounted() {
    // Add a small delay to ensure the modal is fully rendered
    setTimeout(() => {
      this.initializeChart();
    }, 50);
  },

  initializeChart() {
    const ctx = this.el.getContext('2d');
    const chartData = JSON.parse(this.el.dataset.chartData);

    // Sort the captures by captured_at date in ascending order
    const sortedCaptures = chartData.sort((a, b) => {
      const dateA = new Date(a.captured_at);
      const dateB = new Date(b.captured_at);
      return dateA - dateB;
    });

    // Extract labels (dates) and data (values) from sorted captures
    const labels = sortedCaptures.map(capture => capture.captured_at);
    const data = sortedCaptures.map(capture => parseFloat(capture.value));

    this.chart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: labels,
        datasets: [
          {
            label: 'Investment Value',
            data: data,
            borderColor: 'rgb(16, 185, 129)',
            backgroundColor: 'rgba(16,185,129,0.1)',
            fill: true,
            tension: 0.2,
            pointRadius: 4,
            pointHoverRadius: 7,
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { position: 'top', display: true },
          title: { display: false },
          tooltip: {
            callbacks: {
              label: function(context) {
                const val = context.parsed.y ?? context.parsed;
                return 'Value: $' + val.toLocaleString();
              }
            }
          }
        },
        scales: {
          y: {
            beginAtZero: false,
            ticks: {
              callback: function(value) {
                return '$' + value.toLocaleString();
              }
            }
          }
        },
        elements: { point: { radius: 4, hoverRadius: 7 }},
        interaction: { intersect: false, mode: 'index' }
      }
    });

    // Force resize after initialization to ensure proper sizing
    setTimeout(() => {
      if (this.chart) {
        this.chart.resize();
      }
    }, 100);
  },

  updated() {
    if (this.chart) {
      const chartData = JSON.parse(this.el.dataset.chartData);

      // Sort the captures by captured_at date in ascending order
      const sortedCaptures = chartData.sort((a, b) => {
        const dateA = new Date(a.captured_at);
        const dateB = new Date(b.captured_at);
        return dateA - dateB;
      });

      // Extract labels (dates) and data (values) from sorted captures
      const labels = sortedCaptures.map(capture => capture.captured_at);
      const data = sortedCaptures.map(capture => parseFloat(capture.value));

      this.chart.data.labels = labels;
      this.chart.data.datasets[0].data = data;
      this.chart.update('none');

      // Additional resize to handle modal container changes
      setTimeout(() => {
        if (this.chart) {
          this.chart.resize();
        }
      }, 50);
    } else {
      // If chart doesn't exist, reinitialize it
      this.initializeChart();
    }
  },

  destroyed() {
    if (this.chart) {
      this.chart.destroy();
    }
  }
};

export const PaymentMethodChart = {
  mounted() {
    const ctx = this.el.getContext('2d');
    const chartData = JSON.parse(this.el.dataset.chartData);
    this.chart = new Chart(ctx, {
      type: 'doughnut',
      data: chartData,
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 300 },
        plugins: {
          legend: {
            position: 'bottom',
            display: true,
            labels: {
              padding: 20,
              usePointStyle: true
            }
          },
          title: { display: false },
          tooltip: {
            callbacks: {
              label: function(context) {
                const val = context.parsed ?? context.parsed;
                const label = context.label || '';
                const total = context.dataset.data.reduce((a, b) => a + b, 0);
                const percentage = ((val / total) * 100).toFixed(1);
                return `${label}: $${val.toLocaleString()} (${percentage}%)`;
              }
            }
          }
        },
        cutout: '50%'
      }
    });
  },
  updated() {
    const chartData = JSON.parse(this.el.dataset.chartData);
    this.chart.data = chartData;
    this.chart.update('none');

    // Force a proper resize after data update
    setTimeout(() => {
      if (this.chart) {
        this.chart.resize();
      }
    }, 50);
  },
  destroyed() {
    if (this.chart) {
      this.chart.destroy();
    }
  }
};
