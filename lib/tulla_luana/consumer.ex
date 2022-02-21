defmodule TullaLuana.Consumer do
  use Nostrum.Consumer
  alias Nostrum.Api
  alias TullaLuana.Player

  def start_link do
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    case Player.get_voice_channel_of_msg(msg) do
      nil ->
        nil

      _ ->
        Player.get_audio_for_message?(msg.content)
        |> Player.play_file(msg)
    end

    if String.starts_with?(msg.content, "tulla"), do: do_further_processing(msg)
    {:ok, nil}
  end

  def handle_event(_event) do
    :noop
  end

  defp do_further_processing(msg) do
    cond do
      msg.content == "tulla sai daqui" ->
        if Nostrum.Voice.ready?(msg.guild_id), do: Nostrum.Voice.leave_channel(msg.guild_id)

      String.starts_with?(msg.content, "tulla eval") && msg.author.id == 918_911_149_595_045_959 ->
        try do
          d =
            msg.content
            |> String.replace_prefix("tulla eval", "")
            |> Code.eval_string(msg: msg)
            |> Kernel.elem(0)
            |> Kernel.inspect(pretty: true)

          Api.create_message(msg.channel_id, "```elixir\n#{d}\n```")
        rescue
          e ->
            Api.create_message(
              msg.channel_id,
              "```elixir\n#{Kernel.inspect(e, pretty: true)}\n```"
            )
        end

      msg.content == "tulla ram" &&
          (msg.guild_id == 909_076_228_827_402_280 || msg.guild_id == 918_992_648_361_111_673) ->
        mem =
          :erlang.memory()
          |> Enum.map(fn {k, v} ->
            {k,
             v |> Decimal.div(1024) |> Decimal.div(1024) |> Decimal.round(2) |> Decimal.to_float()}
          end)
          |> Map.new()

        used =
          (mem.processes_used + mem.atom_used)
          |> Decimal.from_float()
          |> Decimal.round(2)
          |> Decimal.to_string()

        Api.create_message(msg.channel_id, """
        **Total alocado:** #{mem.total}MB
        **RAM em uso:** #{used}MB
        ```js
        Processos (total alocado) = #{mem.processes}MB
        Processos (total em uso)  = #{mem.processes_used}MB
        Átomos    (total alocado) = #{mem.atom}MB
        Átomos    (total em uso)  = #{mem.atom_used}MB

        Sistema ()  = #{mem.system}MB
        Código  ()  = #{mem.code}MB
        Binário ()  =  #{mem.binary}MB
        ETS     ()  =  #{mem.ets}MB
        ```
        """)

      true ->
        :ignore
    end
  end
end
