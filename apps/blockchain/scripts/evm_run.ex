defmodule EVMRun do
  alias EVM.{VM, ExecEnv}
  alias EVM.Interface.Mock.MockAccountInterface
  alias EVM.Interface.Mock.MockBlockInterface

  def run() do
    {
      args,
      _
    } = OptionParser.parse!(System.argv(),
                                               switches: [
                                                 code: :string,
                                                 code_file: :string,
                                                 address: :string,
                                                 sender: :string,
                                                 value: :integer,
                                                 data: :string,
                                                 originator: :string,
                                                 timestamp: :integer,
                                                 gas_limit: :integer,
                                               ])

    address = Keyword.get(args, :address, "") |> Base.decode16!(case: :mixed)
    originator = Keyword.get(args, :originator, "") |> Base.decode16!(case: :mixed)
    sender = Keyword.get(args, :sender, "") |> Base.decode16!(case: :mixed)
    data = Keyword.get(args, :data, "") |> Base.decode16!(case: :mixed)
    code_file = Keyword.get(args, :code_file)
    gas_limit = Keyword.get(args, :gas_limit, 2000000)
    value = Keyword.get(args, :value, 0)
    code_hex = Keyword.get(args, :code, "")

    code_hex = if code_file do
      File.read!(code_file)
    else
      Keyword.get(args, :code, "")
    end
    machine_code = Base.decode16!(code_hex, case: :mixed)
    account_interface = MockAccountInterface.new()
                        |> MockAccountInterface.add_account(:binary.decode_unsigned(address), %{
                          balance: 0,
                          code: <<>>,
                          storage: %{
                            4 => 13,
                            62514009886607029107290561805838585334079798074568712924583230797734656856475 => 49950757442724281123972775484472007077309159885146335710295725626733554040832,
                          },
                        })

    block_interface = MockBlockInterface.new(%{
      timestamp: Keyword.get(args, :timestamp, 0),
    })

    # IO.inspect originator
    exec_env = %ExecEnv{
      machine_code: machine_code,
      address: address,
      originator: originator,
      sender: sender,
      account_interface: account_interface,
      block_interface: block_interface,
      value_in_wei: value,
      data: data,
    }

    # IO.inspect exec_env.account_interface
    # IO.inspect ExecEnv.non_existent_account?(exec_env, address)

    {gas_remaining, _sub_state, _exec_env, result} = VM.run(gas_limit, exec_env)
    IO.puts "Gas Used: #{gas_limit - gas_remaining}"
    IO.puts "Gas Remaining: #{gas_remaining}"
    IO.puts "Result: #{inspect result}"
  end
end

EVMRun.run()
