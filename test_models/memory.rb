require_relative '../lib/model_base'


class Memory < ModelBase
  self.table_name = 'memories'
  belongs_to :dragon
  has_one_through :rider, :dragon, :rider

  finalize!
end