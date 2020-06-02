# frozen_string_literal: true

class TransferService
  def self.call(from_user_id, to_user_id, amount)

    raise NegativeAmountException if amount.negative?

    sender = User.find(from_user_id)
    receiver = User.find(to_user_id)

    raise NotEnoughMoneyException if sender.balance < amount

    User.transaction do
      reduce_balance!(sender, amount)
      increase_balance!(receiver, amount)
    end
  end

  private

  def reduce_balance!(user, amount)
    user.lock!
    user.update!(balance: user.balance - amount)
  end

  def increase_balance!(user, amount)
    user.lock!
    user.update!(balance: user.balance + amount)
  end
end
