# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TransferService do
  context '#call' do
    subject(:service) { described_class }
    let(:sender) { User.create(name: 'user_1', balance: 100.0) }
    let(:receiver) { User.create(name: 'user_2') }

    describe 'when balance is correct and users exist' do
      it 'should transfer some money' do
        service.call(sender.id, receiver.id, 20.0)

        sender.reload
        expect(sender.balance).to eq(80.0)

        receiver.reload
        expect(receiver.balance).to eq(20.0)
      end

      it 'should transfer all money' do
        service.call(sender.id, receiver.id, 100.0)

        sender.reload
        expect(sender.balance).to be_zero

        receiver.reload
        expect(receiver.balance).to eq(100.0)
      end
    end

    describe 'when amount is negative' do
      it 'should raise an error' do
        expect(service.call(sender.id, receiver.id, -10.0))
          .to raise_error(NegativeAmountException)
      end
    end

    describe 'when user(s) not found' do
      it 'should raise an error' do
        expect(service.call(nil, receiver.id, 20.0))
          .to raise_error(ActiveRecord::RecordNotFound)
        expect(service.call(sender.id, nil, 20.0))
          .to raise_error(ActiveRecord::RecordNotFound)
        expect(service.call(nil, nil, 20.0))
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe 'when sender balance less than amount' do
      it 'should raise an error' do
        expect(service.call(sender.id, receiver.id, 150.0))
          .to raise_error(NotEnoughMoneyException)
      end
    end

    describe 'when service call in multiple threads' do
      it 'should transfer money' do
        (0..2).map do
          Thread.new { service.call(sender.id, receiver.id, 20) }
        end.each(&:join)

        sender.reload
        expect(sender.balance).to eq(60.0)

        receiver.reload
        expect(receiver.balance).to eq(140.0)
      end
    end
  end
end
