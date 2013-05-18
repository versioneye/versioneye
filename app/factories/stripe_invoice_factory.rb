class StripeInvoiceFactory
  def self.create_new(n = 1)
    plan = {name: "Golden Mock"}
    invoice_data = {id: 1,
                    date: (Date.today - 1).iso8601,
                    total: Random.rand * 10 * n,
                    currency: "USD",
                    lines: {subscriptions: [{plan: plan}]}
                    }
    invoice_data
  end

  def self.create_defaults(n = 5)
    invoices = []
    1..n.times {|i| invoices << StripeInvoiceFactory.create_new(i)}
    invoices
  end
end
