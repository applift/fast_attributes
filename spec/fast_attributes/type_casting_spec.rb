require 'spec_helper'

describe FastAttributes::TypeCasting do
  let(:type_casting) { described_class.new }
  let(:value) { 'test' }

  context 'string' do
    before(:each) do
      type_casting.store(String, value)
    end

    it 'must store class and value' do
      expect(type_casting[String]).to eq value
      expect(type_casting[:string]).to eq value
    end

    it 'must check if any key exists' do
      expect(type_casting.key?(String)).to be true
      expect(type_casting.key?(:string)).to be true
      expect(type_casting.key?(:collection_array)).to be false
    end

    it 'must delete all keys by klass' do
      type_casting.delete(String)

      expect(type_casting.key?(String)).to be false
      expect(type_casting.key?(:string)).to be false
    end
  end

  context 'array' do
    before(:each) do
      type_casting.store(Array[Integer], value)
    end

    it 'must store with special key and value' do
      expect(type_casting[:collection_array]).to eq value
    end
  end

  context 'underscore' do
    it 'must convert String klass' do
      expect(type_casting.send(:underscore, String)).to eq :string
      expect(type_casting.send(:underscore, 'String')).to eq :string
      expect(type_casting.send(:underscore, :string)).to eq :string

      expect(type_casting.send(:underscore, 'UserForm')).to eq :user_form
    end

    it 'must convert Integer klass' do
      expect(type_casting.send(:underscore, Integer)).to eq :integer
      expect(type_casting.send(:underscore, 'Integer')).to eq :integer
      expect(type_casting.send(:underscore, :integer)).to eq :integer
    end
  end

  context 'normalize_klass_for_type_name' do
    let(:method_name) { :normalize_klass_for_type_name }

    it 'must convert symbol' do
      expect(type_casting.send(method_name, :test)).to eq :test
    end

    it 'must convert array' do
      expect(type_casting.send(method_name, Array)).to eq :array
    end

    it 'must convert array collection' do
      expect(type_casting.send(method_name, Array[Integer])).to eq :collection_array
    end

    it 'must convert string' do
      expect(type_casting.send(method_name, 'Test')).to eq :test
    end

    it 'must convert integer' do
      expect(type_casting.send(method_name, Integer)).to eq :integer
    end

    it 'must convert custom class' do
      expect(type_casting.send(method_name, InviteForm)).to eq :invite_form
    end

    it 'must convert single set' do
      expect(type_casting.send(method_name, Set)).to eq :set
    end

    it 'must convert collection set' do
      expect(type_casting.send(method_name, Set[InviteForm])).to eq :collection_set
    end
  end
end
