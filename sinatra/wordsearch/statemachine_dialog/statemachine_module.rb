

module IFStateDialog
	"
	paraemterをロードするメソッド
	"
	def preempt(params)
		raise NotImplementedError.new("#{self.class}##{__method__} is not implemented.")
	end
	
	"
	関数を実行する
	"
	def execute()
		raise NotImplementedError.new("#{self.class}##{__method__} is not implemented.")		
	end
	
	"
	テンプレートとして取得すべきページを表す。
	"
	def getTemplatePage()
		raise NotImplementedError.new("#{self.class}##{__method__} is not implemented.")		
	end
	
	def getDataViewFromTables()
		raise NotImplementedError.new("#{self.class}##{__method__} is not implemented.")		
	end
	
	"
	次の画面遷移の情報を与える。
	返値として次のオブジェクトを生成すること。
	"
	def getNextState(params)
		raise NotImplementedError.new("#{self.class}##{__method__} is not implemented.")
	end
	
	def isPostRequest()
		raise NotImplementedError.new("#{self.class}##{__method__} is not implemented.")
	end
	
	def isDestroyed()
		raise NotImplementedError.new("#{self.class}##{__method__} is not implemented.")		
	end
end


