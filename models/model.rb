require 'digest'
require 'bcrypt'
require 'dm-constraints'

require './helpers/helper.rb'

class Message
  include DataMapper::Resource

  property :id,           Serial
  property :body_hash,    String, :unique => true
  property :body,         Text
  property :analyzed,     Boolean, :default => false

  has n, :scans, :through => Resource
  has n, :patterns, :through => Resource
end

class Scan
  include DataMapper::Resource

  property :id,           Serial
  property :active,       Boolean, :default => true
  property :created_at,   DateTime
  property :sensitivity,  Float, :default => 1.0
  property :separator,    String
  property :packed,       Boolean, :default => true
  property :selected,     Boolean, :default => false
  property :removing,     Boolean, :default => false

  has n,  :messages, :through => Resource
  has n,  :patterns, :constraint => :set_nil

  belongs_to  :parent, :model => 'Pattern', :required => false
end

class Pattern
  include DataMapper::Resource

  property :id,             Serial
  property :body,           Text
  property :body_split,     Text, :default => lambda { |r, p| body_split(r.body) }
  property :name,           Text, :default => lambda { |r, p| pattern_name(r.body_split) }
  property :active_filter,  Boolean, :default => false
  property :final,          Boolean, :default => false
  property :finalized,      Boolean, :default => false
  property :selected,       Boolean, :default => false
  property :edit,           Boolean, :default => false
  property :packed,         Boolean, :default => true

  belongs_to :scan,       :required => false
  has n,     :messages,   :through => Resource
  has n,     :children,   :model => 'Scan', :through => Resource
end

class User
  include DataMapper::Resource
  include BCrypt

  property :id, Serial, :key => true
  property :username, String, :length => 3..50
  property :password, BCryptHash
end

