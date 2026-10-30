# frozen_string_literal: true

# Statistic — Atomic purpose: generic polymorphic metric row owned by a domain
# record and optionally tagged.
#
# Why it exists: dashboards need to attach computed counters to many owner types
# without a per-owner statistics table; tags let stats be grouped by the ABAC tag
# vocabulary.
# How it works: belongs_to :owner, polymorphic: true; TagConcern adds tags through
# StatisticTagAppointment.
# Main associations: belongs_to :owner (polymorphic, required); has_many :tags
# through :statistic_tag_appointments (via TagConcern).
class Statistic < ApplicationRecord
  include TagConcern

  belongs_to :owner, polymorphic: true
end
