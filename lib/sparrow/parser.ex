defmodule Sparrow.Parser do
  def parse(str) do
    str
    |> String.split("--batch")
    |> Enum.reduce([], &get_data/2)
    |> Enum.reject(fn data -> Map.get(data, "body") |> is_nil() end)
  end

  defp get_data("_" <> data, acc) do
    result = data
    |> String.split("\r\n")
    |> Enum.reduce(%{}, &parse_data/2)

    [result | acc]
  end
  defp get_data(_, acc), do: acc

  defp parse_data("", acc), do: acc
  defp parse_data("{" <> _data = data, acc) do
    Map.put(acc, "body", Jason.decode!(data))
  end
  defp parse_data(data, acc) do
    headers = Map.get(acc, "headers", [])
    case String.contains?(data, ":") do
      true -> 
        [key, value] = String.split(data, ":")
        Map.put(acc, "headers", [{String.downcase(key), value} | headers])
      _ -> extended_parse(data, acc)
    end
  end

  defp extended_parse("HTTP" <> code, acc) do
    headers = Map.get(acc, "headers", [])
    status = code |> String.split(" ") |> Enum.at(1)
    Map.put(acc, "headers", [{":status", status} | headers])
  end
  defp extended_parse(id, acc), do: Map.put(acc, "id", id)
end
