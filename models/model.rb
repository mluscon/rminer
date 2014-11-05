require 'digest'

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
  property :tag,          String
  property :active,       Boolean, :default => true
  property :created_at,   DateTime
  property :sensitivity,  Integer, :default => 1
  property :separator,    String
  property :hidden,       Boolean, :default => true
  property :selected,     Boolean, :default => false

  has n,  :messages, :through => Resource
  has n,  :patterns
  has n,  :children, self, :child_key => [ :parent_id ]
  belongs_to  :parent, self, :required => false
end

class Pattern
  include DataMapper::Resource

  property :id,           Serial
  property :body,         Text
  property :final,        Boolean, :default => false
  property :selected,     Boolean, :default => false
  property :final,        Boolean, :default => false

  belongs_to :scan
  has n,  :messages, :through => Resource
end
