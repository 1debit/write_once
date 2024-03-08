# frozen_string_literal: true
class ApplicationRecord
  attr_reader :values

  def new_record?
    false
  end

  def initialize
    @values = HashWithIndifferentAccess.new
  end

  def read_attribute(attr_name)
    @values[attr_name]
  end

  def write_attribute(attr_name, value)
    @values[attr_name] = value
  end

  def _write_attribute(attr_name, value)
    @values[attr_name] = value
  end

  def method_missing(name, *args)
    if name.to_s.end_with?("=")
      write_attribute(name.to_s.chomp("="), args.first)
    else
      read_attribute(name)
    end
  end
end

class WriteOnceTestClass < ApplicationRecord
  include WriteOnce

  def initialize(attributes = {})
    super()
    attributes.each { |key, value| write_attribute(key, value) }
  end
  #self.table_name = "limit_units"

  #belongs_to :spot_me_account, class_name: "SpotMe::Account"

  attr_write_once :campaign_code, :uid, :spot_me_account_id
end

RSpec.describe WriteOnce do
  subject(:write_only_class_instance) do
    WriteOnceTestClass.new(spot_me_account_id: 12, campaign_code: "evergreen_raf")
  end

  it "returns a list of write only attributes" do
    expect(WriteOnceTestClass.write_once_attributes).to eq(
      %w[campaign_code uid spot_me_account_id],
    )
  end

  it "allows nullable values to be overwritten in memory" do
    expect(write_only_class_instance.uid).to be_nil

    write_only_class_instance.uid = "example"

    expect(write_only_class_instance.uid).to eq("example")
  end

  it "allows nullable values to be overwritten as an update" do
    expect(write_only_class_instance.uid).to be_nil

    write_only_class_instance.update!(uid: "example")

    expect(write_only_class_instance.uid).to eq("example")
  end

  it "allows a non-nullable value to be overwritten in memory before save" do
    expect(write_only_class_instance.campaign_code).to eq("evergreen_raf")

    write_only_class_instance.campaign_code = "example"

    expect(write_only_class_instance.campaign_code).to eq("example")
  end

  it "allows a non-nullable value to be overwritten via update before save" do
    expect(write_only_class_instance.campaign_code).to eq("evergreen_raf")

    write_only_class_instance.update!(campaign_code: "example")

    expect(write_only_class_instance.campaign_code).to eq("example")
  end

  context "when the model has been persisted" do
    before do
      write_only_class_instance.save!
    end

    it "does NOT allow a non-nullable value to be overwritten in memory" do
      expect(write_only_class_instance.campaign_code).to eq("evergreen_raf")
      expect do
        write_only_class_instance.campaign_code = "example"
      end.to raise_error(WriteOnceAttributeError)

      expect(write_only_class_instance.campaign_code).to eq("evergreen_raf")
    end

    it "does NOT allow a non-nullable value to be overwritten via update" do
      expect(write_only_class_instance.campaign_code).to eq("evergreen_raf")
      expect do
        write_only_class_instance.update(campaign_code: "example")
      end.to raise_error(WriteOnceAttributeError)

      expect(write_only_class_instance.campaign_code).to eq("evergreen_raf")
    end

    context "with another account" do
      let(:other_spot_me_account) { create(:account) }

      it "does NOT allow updates via model association" do
        expect(write_only_class_instance.spot_me_account_id).to eq(spot_me_account.id)

        expect do
          write_only_class_instance.update(spot_me_account: other_spot_me_account)
        end.to raise_error(WriteOnceAttributeError)

        expect(write_only_class_instance.spot_me_account.id).to eq(spot_me_account.id)
      end
    end
  end

  xcontext "when the configuration is not set to strict" do
    before do
      write_only_class_instance.save!
      Rails.application.config.write_only_nil_strict = false
      allow(Rails.logger).to receive(:warn)
    end

    it "WARNS a non-nullable value has been overwritten in memory" do
      expect(write_only_class_instance.campaign_code).to eq("evergreen_raf")
      write_only_class_instance.campaign_code = "example"

      expect(Rails.logger).to have_received(:warn)
      expect(write_only_class_instance.campaign_code).to eq("example")
    end

    it "WARNS a non-nullable value has been overwritten via update" do
      expect(write_only_class_instance.campaign_code).to eq("evergreen_raf")
      write_only_class_instance.update(campaign_code: "example")

      expect(Rails.logger).to have_received(:warn)
      expect(write_only_class_instance.campaign_code).to eq("example")
    end

    context "with another account" do
      let(:other_spot_me_account) { create(:account) }

      it "WARNS there was an update via model association" do
        expect(write_only_class_instance.spot_me_account_id).to eq(spot_me_account.id)
        write_only_class_instance.update(spot_me_account: other_spot_me_account)

        expect(Rails.logger).to have_received(:warn)
        expect(write_only_class_instance.spot_me_account.id).to eq(other_spot_me_account.id)
      end
    end
  end
end
