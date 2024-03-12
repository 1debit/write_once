# frozen_string_literal: true

class WriteOnceTestClass < ActiveRecord::Base
  include WriteOnce

  self.table_name = "users"

  belongs_to :account, class_name: "AccountTestClass"

  attr_write_once :experiment_group, :account_id, :uid
end

class AccountTestClass < ActiveRecord::Base
  include WriteOnce

  self.table_name = "accounts"
end

RSpec.describe WriteOnce do
  subject(:write_only_class_instance) do
    WriteOnceTestClass.new(experiment_group: "alpha", account_id: account.id)
  end

  let(:account) { AccountTestClass.create }

  it "returns a list of write only attributes" do
    expect(WriteOnceTestClass.write_once_attributes).to eq(
      %w[experiment_group account_id uid],
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
    expect(write_only_class_instance.experiment_group).to eq("alpha")

    write_only_class_instance.experiment_group = "beta"

    expect(write_only_class_instance.experiment_group).to eq("beta")
  end

  it "allows a non-nullable value to be overwritten via update before save" do
    expect(write_only_class_instance.experiment_group).to eq("alpha")

    write_only_class_instance.update!(experiment_group: "beta")

    expect(write_only_class_instance.experiment_group).to eq("beta")
  end

  context "when the model has been persisted" do
    before do
      write_only_class_instance.save!
    end

    it "does NOT allow a value to be overwritten in memory" do
      expect(write_only_class_instance.experiment_group).to eq("alpha")
      expect do
        write_only_class_instance.experiment_group = "beta"
      end.to raise_error(WriteOnceAttributeError)

      expect(write_only_class_instance.experiment_group).to eq("alpha")
    end

    it "does NOT allow a value to be overwritten via update" do
      expect(write_only_class_instance.experiment_group).to eq("alpha")
      expect do
        write_only_class_instance.update(experiment_group: "beta")
      end.to raise_error(WriteOnceAttributeError)

      expect(write_only_class_instance.experiment_group).to eq("alpha")
    end

    context "with a different account" do
      let(:other_account) { AccountTestClass.create }

      it "does NOT allow updates via model association" do
        expect(write_only_class_instance.account_id).to eq(account.id)

        expect do
          write_only_class_instance.update(account: other_account)
        end.to raise_error(WriteOnceAttributeError)

        expect(write_only_class_instance.account.id).to eq(account.id)
      end
    end
  end

  context "when the configuration is not set to strict" do
    before do
      write_only_class_instance.save!
      WriteOnce.config.enforce_errors = false
      allow(WriteOnce.config.logger).to receive(:warn)
    end

    it "WARNS a non-nullable value has been overwritten in memory" do
      expect(write_only_class_instance.experiment_group).to eq("alpha")
      write_only_class_instance.experiment_group = "beta"

      expect(WriteOnce.config.logger).to have_received(:warn)
      expect(write_only_class_instance.experiment_group).to eq("beta")
    end

    it "WARNS a non-nullable value has been overwritten via update" do
      expect(write_only_class_instance.experiment_group).to eq("alpha")
      write_only_class_instance.update(experiment_group: "beta")

      expect(WriteOnce.config.logger).to have_received(:warn)
      expect(write_only_class_instance.experiment_group).to eq("beta")
    end

    context "with another account" do
      let(:other_account) { AccountTestClass.create }

      it "WARNS there was an update via model association" do
        expect(write_only_class_instance.account_id).to eq(account.id)
        write_only_class_instance.update(account: other_account)

        expect(WriteOnce.config.logger).to have_received(:warn)
        expect(write_only_class_instance.account.id).to eq(other_account.id)
      end
    end
  end
end
