# frozen_string_literal: true

# SignInToken — Atomic purpose: signed, revocable token that authorizes one
# passwordless sign-in for a User.
#
# Why it exists: lets a verified user prove email ownership without entering a
# password; each token belongs to one user and can be revoked in bulk.
# How it works: the passwordless flow creates a token, emails its signed id, and
# `SignInToken.find_signed!` resolves it back to the user. After a successful
# sign-in, `user.sign_in_tokens.delete_all` invalidates every outstanding link.
# Main associations: belongs_to :user (required).
class SignInToken < ApplicationRecord
  belongs_to :user
end
