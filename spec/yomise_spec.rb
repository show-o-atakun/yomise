# frozen_string_literal: true

RSpec.describe Yomise do
  it "has a version number" do
    expect(Yomise::VERSION).not_to be nil
  end

  it "does correct behavior about reconvert_utf8 paramater" do
    df = Yomise.read_csv("./spec/fixtures/files/test.csv", encoding: "cp932", reconvert_utf8: true)
    p df
    p df.vectors
  end

  it "does work about available function" do
    df = Yomise.read_csv("./spec/fixtures/files/test.csv", encoding: "cp932", reconvert_utf8: true)
    p Yomise.available(df)
  end
  
  it "Rover Categorize works" do
    # 入力
    input_path = "./spec/fixtures/files/test.csv"

    # 実行
    df = Yomise.read_csv(input_path, format: :array, encoding: "cp932", reconvert_utf8: true, format: :rover)
    # categories = df.categorize("column1")
    # categories = df.categorize(["column1"])
    categories = df.categorize(["column1", "column2"])
    categories.each do |c|
      puts c 
      p df.get_category(c)
    end
  end

  it "Rover map works" do
    input_path = "./spec/fixtures/files/test.csv"
    # 実行
    df = Yomise.read_csv(input_path, encoding: "cp932", reconvert_utf8: true, format: :rover)
    p df.map { _1["column1"] == "く"} 
  end

  it "write_excel works" do
    input_path = "./spec/fixtures/files/test.csv"
    # 実行
    df = Yomise.read_csv(input_path, encoding: "cp932", reconvert_utf8: true, format: :rover)
    Yomise::write_excel([df, df], "./test.xlsx", sheetnames: ["Test1", "Test2"])

    dfdaru = Yomise.read_csv(input_path, encoding: "cp932", reconvert_utf8: true, format: :daru)
    Yomise::write_excel [df, df], "./test_daru.xlsx"
  end
end
