defmodule ImportInvestments do
  def run do
    raw_data()
    |> String.split("\n", trim: true)
    |> Enum.each(fn line ->
      [name | values] = String.split(line, ",", trim: true)

      initial_value =
        List.first(values) |> String.replace(",", "") |> String.to_float() |> Decimal.from_float()

      IO.inspect(name, label: "Importing investment")
      IO.inspect(values, label: "Values")
      IO.inspect(initial_value, label: "initial_value")

      start_date = ~D[2024-03-15]

      {:ok, investment} =
        FinTrack.Investments.create_investment(
          %{"name" => name, "initial_value" => initial_value},
          1
        )

      Enum.with_index(values)
      |> Enum.each(fn {value_str, index} ->
        if index > 0 do
          captured_at = Date.shift(start_date, month: index)
          IO.inspect(value_str, label: "  Adding value capture index#{index} at #{captured_at}")
          value = String.replace(value_str, ",", "") |> String.to_float() |> Decimal.from_float()

          # captured_at = Date.add(~D[2022-01-01], index - 1)  # Assuming the first value corresponds to 2022-01-01
          FinTrack.Investments.add_value_capture(investment.id, %{
            "captured_at" => captured_at,
            "value" => value
          })
        end
      end)
    end)
  end

  defp raw_data do
    """
    Banamex Fondo Inv,2400000.00,2427590.00,2497880.57,2522052.12,2544736.18,2569077.11,2592881.28,2610129.27,2630073.00,2649260.09,2661590.18,2691518.02,2703609.61,2715170.68,2736693.72,2752963.83,2768379.24,3008071.82
    Hey,1070000.00,1070000.00,1091254.00,1101455.17,1122113.27,1132592.30,1143169.19,1153844.85,1164171.50,1174590.57,1185102.58,1185102.89,1195248.42,1205015.98,1395918.44,1407325.88,1429869.40,1440442.17,1449972.77
    GBM ETF,424500.00,405885.70,412998.00,444571.00,448146.70,466080.00,472169.00,493285.75,519294.69,568509.00,653580.21,686736.00,643246.00,633578.00,651014.00,649694.00,809783.00,793847.00,809578.00
    Actinver,714306.00,719402.00,724491.70,728678.49,736076.57,743553.62,750502.13,755349.16,760422.18,767298.27,771890.05,779659.55,785796.64,791135.24,795789.21,801255.31,802430.58,808146.88,813569.19
    Cetes,267000.00,270306.00,272812.86,275403.23,277832.46,280728.01,283291.69,285371.26,287720.20,290147.93,292433.33,294813.45,296822.86,359123.24,361687.42,364259.68,366438.00,369394.80,371853.88
    """
  end
end
