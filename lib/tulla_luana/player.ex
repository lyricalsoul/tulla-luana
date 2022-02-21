defmodule TullaLuana.Player do
  alias Nostrum.Voice
  alias Nostrum.Cache.GuildCache

  @audio_mappings %{
    "não tenho medo" => "nao-tenho-medo",
    "nao tenho medo" => "nao-tenho-medo",
    "beijos estrelados" => "beijos-estrelados",
    "mudei muito sim" => "mudei-muito-sim",
    "vou te processar" => "vou-te-processar",
    "printei tudo" => "vou-te-processar",
    "ladra" => "ladra",
    "meu deus lady gaga" => "lady-gaga",
    "gaga flopou" => "lady-gaga",
    "lady gagaaaaaaaaaaa" => "lady-gaga",
    "stupid love ladeirou" => "lady-gaga",
    "stupid love despencou" => "lady-gaga",
    "pessoas inteligentes entenderiam" => "pessoas-inteligentes",
    "vai estudar" => "vai-estudar",
    "ganhou mas nao vai levar" => "ganhou",
    "ganhou mas não vai levar" => "ganhou",
    "em virtude de acordo celebrado" => "adjetivos",
    "fui processada" => "adjetivos",
    "utilizei adjetivos injustos" => "adjetivos",
    "patria educadora" => "patria-educadora",
    "pátria educadora" => "patria-educadora",
    "lambe meu cu" => "lambe-meu-cu",
    "foi isso que eu pedi" => "nao-foi-isso",
    "telephone - tulla luana" => "telephone",
    "a canetada de" => "demais",
    "acima de mim" => "ninguem-acima",
    "acorda sua" => "acorda",
    "esse momento é meu" => "momento",
    "esse momento e meu" => "momento",
    "esse momento eh meu" => "momento",
    "que sabor delicioso" => "que-sabor",
    "acaba de falecer a web diva" => "acaba-de-falecer"
  }

  def init do
    :ets.new(:guild_mapping, [:set, :public, :named_table])
  end

  def get_voice_channel_of_msg(msg) do
    msg.guild_id
    |> GuildCache.get!()
    |> Map.get(:voice_states)
    |> Enum.find(%{}, fn v -> v.user_id == msg.author.id end)
    |> Map.get(:channel_id)
  end

  def play_file(nil, _), do: nil

  def play_file(file, msg) do
    case {Voice.playing?(msg.guild_id), get_voice_channel_of_msg(msg)} do
      {_, nil} -> nil
      {false, channel} -> connect_and_play_file(msg.guild_id, channel, file)
      {true, _} -> nil
    end
  end

  def connect_and_play_file(guild, channel, file) do
    case Voice.ready?(guild) do
      false ->
        Voice.join_channel(guild, channel, false, true)
        wait_until_ready(guild, channel, file)

      true ->
        do_play_file(file, guild)
    end
  end

  defp wait_until_ready(guild, channel, file) do
    if Voice.ready?(guild) do
      connect_and_play_file(guild, channel, file)
    else
      wait_until_ready(guild, channel, file)
    end
  end

  defp do_play_file(file, guild) do
    Voice.play(guild, file)
    update_guild_timestamp(guild)
    :timer.apply_after(30000, __MODULE__, :clean_up_connection, [guild])
  end

  def get_audio_for_message?(word) do
    @audio_mappings
    |> Enum.filter(fn {k, _} -> String.contains?(String.downcase(word), k) end)
    |> Enum.map(fn {_, v} -> "./assets/" <> v <> ".mp3" end)
    |> Enum.at(0)
  end

  defp update_guild_timestamp(guild) do
    :ets.insert(:guild_mapping, {guild, :os.system_time(:second)})
  end

  def get_guild_timestamp(guild) do
    [{_, time}] = :ets.lookup(:guild_mapping, guild)
    time
  end

  def clean_up_connection(guild) do
    current_time = :os.system_time(:second)

    unless Voice.playing?(guild) do
      cond do
        current_time - get_guild_timestamp(guild) >= 30 ->
          Voice.leave_channel(guild)

        true ->
          :timer.apply_after(15000, __MODULE__, :clean_up_connection, [guild])
      end
    end
  end
end
