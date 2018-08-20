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
                                                 address: :string,
                                                 originator: :string,
                                                 timestamp: :integer,
                                                 gas_limit: :integer,
                                               ])
    account_interface = MockAccountInterface.new()
    block_interface = MockBlockInterface.new(%{
      timestamp: Keyword.get(args, :timestamp, 0),
    })

    gas_limit = Keyword.get(args, :gas_limit, 2000000)
    code_hex = Keyword.get(args, :code, "")
    machine_code = Base.decode16!(code_hex, case: :mixed)

    exec_env = %ExecEnv{
      machine_code: machine_code,
      address: Keyword.get(args, :address, "") |> Base.decode16,
      originator: Keyword.get(args, :originator, "") |> Base.decode16,
      account_interface: account_interface,
      block_interface: block_interface,
    }

    {gas_remaining, _sub_state, _exec_env, result} = VM.run(gas_limit, exec_env)
    IO.puts "Gas Remaining: #{gas_remaining}"
    IO.puts "Result: #{inspect result}"
  end
end

EVMRun.run()
