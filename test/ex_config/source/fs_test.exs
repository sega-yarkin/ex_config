defmodule ExConfig.Source.FSTest do
  use ExUnit.Case, async: false
  alias ExConfig.Param
  alias ExConfig.Source.FS

  @p %Param{}

  defp rnd_str(n \\ 10),
    do: :crypto.strong_rand_bytes(n) |> Base.encode32(case: :lower)

  defp rnd_filename(tmp_dir),
    do: Path.join(tmp_dir, rnd_str())

  defp rnd_file(tmp_dir) do
    name = rnd_filename(tmp_dir)
    data = rnd_str()
    File.write!(name, data)
    {name, data}
  end

  setup_all do
    tmp_dir = Path.join(System.tmp_dir!(), rnd_str())
    File.mkdir_p!(tmp_dir)
    on_exit(fn ->
      File.rm_rf!(tmp_dir)
    end)
    {:ok, tmp_dir: tmp_dir}
  end

  describe "FileContent" do
    test "handle", %{tmp_dir: tmp_dir} do
      handle = &FS.FileContent.handle(%FS.FileContent{path: &1}, @p)
      handle_def = &FS.FileContent.handle(%FS.FileContent{path: &1, default: &2}, @p)

      {file1, data1} = rnd_file(tmp_dir)
      {file2, data2} = rnd_file(tmp_dir)
      file3 = rnd_filename(tmp_dir)
      file4 = "/root/file"

      assert handle.(tmp_dir) == {:ok, nil}
      assert handle.(file3) == {:ok, nil}
      assert handle.([file3, file4]) == {:ok, nil}
      assert handle.(file1) == {:ok, data1}
      assert handle.([file1, file2]) == {:ok, data1}
      assert handle.([file2, file1]) == {:ok, data2}
      assert handle.([file3, file4, file1]) == {:ok, data1}

      assert handle_def.(tmp_dir, :default) == {:ok, :default}
      assert handle_def.(file3, :default) == {:ok, :default}
      assert handle_def.([file3, file4], :default) == {:ok, :default}
      assert handle_def.(file1, :default) == {:ok, data1}
      assert handle_def.([file1, file2], :default) == {:ok, data1}
      assert handle_def.([file2, file1], :default) == {:ok, data2}
      assert handle_def.([file3, file4, file1], :default) == {:ok, data1}

      File.rm!(file1)
      File.rm!(file2)
    end

    test "missing or wrong path option" do
      assert_raise ArgumentError, ~r/the following keys must also be given/, fn -> struct!(FS.FileContent, default: :default) end
      assert_raise FunctionClauseError, fn -> FS.FileContent.handle(%FS.FileContent{path: :test}, @p) end
    end

    test "invoke_source", %{tmp_dir: tmp_dir} do
      invoke = &Param.maybe_invoke_source(%Param{data: {FS.FileContent, &1}})

      {file1, data1} = rnd_file(tmp_dir)
      {file2, data2} = rnd_file(tmp_dir)
      file3 = rnd_filename(tmp_dir)
      file4 = "/root/file"

      assert invoke.(path: tmp_dir) == %Param{data: nil, exist?: false}
      assert invoke.(path: [file3, file4]) == %Param{data: nil, exist?: false}
      assert invoke.(path: [file1, file2]) == %Param{data: data1, exist?: true}
      assert invoke.(path: file2) == %Param{data: data2, exist?: true}

      assert invoke.(path: file1, default: :default) == %Param{data: data1, exist?: true}
      assert invoke.(path: file3, default: :default) == %Param{data: :default, exist?: true}

      File.rm!(file1)
      File.rm!(file2)
    end
  end

  describe "DirContent" do
    test "handle" do
      handle = &elem(FS.DirContent.handle(%FS.DirContent{path: &1}, @p), 1)
      all_in = &Enum.all?(&1, fn el -> el in &2 end)

      top_dir = File.cwd!()
      top_files = ["mix.exs", "README.md", "lib", "config"]

      assert all_in.(top_files, handle.(top_dir))
      assert all_in.(top_files, handle.([top_dir]))
      assert all_in.(top_files, handle.(["/somenonexistingpath", top_dir]))
      refute all_in.(top_files, handle.([Path.join(top_dir, "lib"), top_dir]))
      assert handle.(["/somenonexistingpath"]) == nil
    end

    test "invoke_source" do
      invoke = &Param.maybe_invoke_source(%Param{data: {FS.DirContent, &1}})

      top_dir = File.cwd!()
      lib_dir = Path.join(top_dir, "lib")
      lib_files = ["ex_config", "ex_config.ex"]

      assert invoke.(path: "/somenonexistingpath") == %Param{data: nil, exist?: false}
      assert invoke.(path: ["/somenonexistingpath", "/anotherone"]) == %Param{data: nil, exist?: false}
      res = invoke.(path: lib_dir)
      assert res.exist?
      assert Enum.sort(res.data) == Enum.sort(lib_files)

      assert invoke.(path: "/somenonexistingpath", default: :default) == %Param{data: :default, exist?: true}
      res = invoke.(path: lib_dir, default: :default)
      assert res.exist?
      assert Enum.sort(res.data) == Enum.sort(lib_files)
    end
  end

  describe "Glob" do
    test "handle" do
      handle = &elem(FS.Glob.handle(%FS.Glob{expr: &1}, @p), 1)

      files = handle.("_build/{dev,test}/**/*.beam")
      assert length(files) > 10
      assert "_build/test/lib/ex_config/ebin/Elixir.ExConfig.beam" in files
          or "_build/dev/lib/ex_config/ebin/Elixir.ExConfig.beam" in files
      refute "config/config.exs" in files

      files = handle.(["_build/{dev,test}/**/*.beam", "config/*.exs"])
      assert length(files) > 10
      assert "_build/test/lib/ex_config/ebin/Elixir.ExConfig.beam" in files
          or "_build/dev/lib/ex_config/ebin/Elixir.ExConfig.beam" in files
      assert "config/config.exs" in files
    end
  end
end
