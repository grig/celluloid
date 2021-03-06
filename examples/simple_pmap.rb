module Enumerable
  # Simple parallel map using Celluloid::Futures
  def pmap(&block)
    futures = map { |elem| Celluloid::Future(elem, &block) }
    futures.map { |future| future.value }
  end
end