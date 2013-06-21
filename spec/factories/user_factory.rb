
FactoryGirl.define do
  factory :user do
    terms true
    datenerhebung true
    salt "sugar"
    password "12345"
    github_token "random-token-bla-bla"
    encrypted_password Digest::SHA2.hexdigest("sugar--12345") 
  end
end

