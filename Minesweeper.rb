# Classe Cell - Todas as posições do jogo serão uma célula na qual armazenará as coordenadas da mesma, o marcador que é 
# o status dela, ou seja, se é uma bomba ou se está vazia. E um marcador de visibilidade, no qual impedirá que seja jogada
# duas vezes. A função setCellMap irá colocar o marcador em cada célula do mapa. Função getMarker retornará o marcador.
class Cell
	attr_reader :x
	attr_reader :y
	attr_reader :marker
	attr_reader :visible

	attr_writer :x
	attr_writer :y
	attr_writer :marker
	attr_writer :visible

	def initialize(x, y, marker, visible = false)
		@x, @y, @marker, @visible = x, y, marker, visible
	end

	def setcellMap(cellMap)
		return cellMap[@x][@y] = @marker
	end

	def getMarker()
		return marker
	end
end

# ------------------------------------- BOARDS -------------------------------------

# É utilizado dois tabuleiros no jogo, MineBoard que é um mapa com tudo revelado, todas as posições e o que possui nas
# mesmas, e PlayBoard que é o tabuleiro jogável, onde cada coordenada inserida para jogar, ainda é desconhecida.
# Ambos os tabuleiros possuem um Array bidimensional, onde fica cada célula, sendo cada uma um objeto Cell.
# Ao termino do jogo, é revelado o tabuleiro MineBoard para mostrar todas as células do jogo.

class MineBoard
	# Constantes contendo o valor usado nos marcadores dentro das células
	@@MINE = "#"
	@@CLEAR = " "
	@@UNKNOWN = "."
	@@FLAG = "F"

	attr :cellMap

	# Quando um objeto do tipo MineBoard, na sua inicialização será criado o cellMap, que é o mapa das células do jogo
	# e criada uma nova célula para cada posição, sendo que a nova célula será uma célula vazia e o valor de cada uma
	# será definido através de outras funções da classe.
	def initialize(width, height, numMines)
		@width, @height, @numMines = width, height, numMines

		@cellMap = []
		@width.times do |x|
			col = []
			@height.times do |y|
				col << Cell.new(x, y, @@CLEAR)
			end
			@cellMap << col
		end
		createMines()
		setup()
		saveCloseMines()
	end

	# Função para criar as minas em lugares aleatórios e sem repetir posições
	def createMines()
		countMine = 0
		@mineList = []
		while countMine < @numMines
			mine = nil
			while !mine
				x = rand(@width)
				y = rand(@height)
				mine = [x, y]

				if @mineList.include?(mine)
					mine = nil
				else
					@mineList << mine
				end
			end
			countMine += 1
		end
	end

	# Função para colocar as bombas dentro do tabuleiro nas posições predefinidas aleatóriamente.
	def setup()
		@mineList.each do |mine|
			x = mine[0]
			y = mine[1]
			@cellMap[x][y] = Cell.new(x, y, @@MINE)
		end
	end

	# Função a qual salva nas células o valor de bombas em posições adjacentes, incluindo diagonais.
	def saveCloseMines()
		countW = 0
		while countW < @width
			countH = 0
			num = 0

			while countH < @height
				cell = @cellMap[countW][countH]
				if  !(cell.marker == @@MINE)
					num = numCloseMines(cell)
					if num > 0
						cell.marker = String(num)
					end
				end
				countH += 1
			end

			countW += 1
		end
	end

	# Função que pega a célula que foi passada no parâmetro e verifica se tem alguma mina em volta dela.
	def numCloseMines(cell)
		close = 0

		@mineList.each do |mine|
			x = (cell.x - mine[0])
			y = (cell.y - mine[1])

			x = (x).abs
			y = (y).abs

			if x < 2 && y < 2
				close += 1
			end
		end
		return close
	end

	# Função que retorna o tabuleiro inteiro.
	def board_state()
		return @cellMap
	end
end


# Tabuleiro jogável, sempre que for escolhida uma posição para revelar o que possui na mesma, será verificado
# no MineBoard o conteúdo daquela célula, e passado para esse tabuleiro o valor.
class PlayBoard
	# Constantes contendo o valor usado nos marcadores dentro das células
	@@MINE = "#"
	@@CLEAR = " "
	@@UNKNOWN = "."
	@@FLAG = "F"

	attr :cellMap

	# Quando um objeto do tipo PlayBoard, na sua inicialização será criado o cellMap, que é o mapa das células do jogo
	# e criada uma nova célula para cada posição, sendo que a nova célula será uma célula vazia e o valor de cada uma
	# será definido no decorrer do jogo
	def initialize(width, height)
    @width,@height = width, height
    
    @cellMap = []
		@width.times do |x|
			col = []
			@height.times do |y|
				col << Cell.new(x, y, @@UNKNOWN)
			end
			@cellMap << col
		end
	end

	# Verifica se a posição que escolhida para jogar é válida, se já foi jogada ou é uma bandeira, não é jogável, caso contrário
	# returna true, por ser válido
	def playable(x, y)
		puts @cellMap[x][y].getMarker
		if @cellMap[x][y].getMarker == @@UNKNOWN && !@cellMap[x][y].visible
			if @cellMap[x][y].marker == @@FLAG
				return false
			end
			return true
		end
		return false
	end

	# Verifica se a célula da posição escolhida já foi jogada, caso não tenha sido jogada, torná-la uma bandeira é possível.
	def validFlag(x, y)
		if @cellMap[x][y].marker == @@FLAG || @cellMap[x][y].marker == @@UNKNOWN
			if !@cellMap[x][y].visible
				return true
			end
		end
		return false
	end

	# Retorna o atual estado do tabuleiro.
	def board_state()
		return @cellMap
	end
end

# ----------------------------------- END BOARDS -----------------------------------

# Classe Minesweeper - É a classe principal do funcionamento do jogo, onde possui a maioria das funções e onde é feita
# a integração com as outras classes, todas as entradas do funcionamento do jogo são feitas com parâmetros nessa class
# e com seus métodos.

class Minesweeper
	# Constantes contendo o valor usado nos marcadores dentro das células
	@@MINE = "#"
	@@CLEAR = " "
	@@UNKNOWN = "."
	@@FLAG = "F"

	# Inicialização da classe, verifica se o número de bombas é aceitável para o jogo e não supera o número de células
	# no mesmo, cria as váriaveis utilizadas na classe e os tabuleiros são definidos como objetos
	def initialize(width, height, numMines)
		@width, @height, @numMines = width, height, numMines

		if numMines > (@width * @height)
			@numMines = (@width * @height) - 1
		end

		@gameOver = false
		@safeMines = 0

		@mineBoard = MineBoard.new(@width, @height, @numMines)
		@playBoard = PlayBoard.new(@width, @height)
	end

	# Função que verifica se as células ao redor da célula escolhida são brancas, apenas caso a célula escolhida também seja,
	# se for o caso, recursivamente verifica todas as células ao redor até atingir alguma borda.
	def fillBlank(x, y)
		if !@playBoard.cellMap[x][y].visible && @playBoard.cellMap[x][y]
			if @mineBoard.cellMap[x][y].marker == @@CLEAR
				@playBoard.cellMap[x][y].marker = @@CLEAR
				@playBoard.cellMap[x][y].visible = true
			else
				return
			end

			if x > 0
				fillBlank(x - 1, y)
			end
			if x < (@width - 1)
				fillBlank(x + 1, y)
			end
			if y < (@height - 1)
				fillBlank(x, y + 1)
			end
			if y > 0
				fillBlank(x, y - 1)
			end
			if x > 0 && y < (@width - 1)
				fillBlank(x - 1, y + 1)
			end
			if x < (@height - 1) && y > 0
				fillBlank(x + 1, y - 1)
			end
			if x > 0 && y > 0
				fillBlank(x - 1, y - 1)
			end
			if x < (@width - 1) && y < (@height - 1)
				fillBlank(x + 1, y + 1)
			end
		end
		return
	end

	# Função de jogar principal, verifica no início se é possível jogar, caso seja uma célula jogável, ou seja, ainda não foi revelada.
	# Verifica o marcador da célula escolhida, se for uma bandeira, ignora a mesma, caso contrário, chama as funções de acordo com a
	# necessidade.
	def play(x, y)

		if @playBoard.playable(x, y)
			cell = @playBoard.cellMap[x][y].marker
			openCell = @mineBoard.cellMap[x][y].marker

			if cell == @@UNKNOWN && openCell != @@MINE

				if !@playBoard.cellMap[x][y].visible && openCell == @@CLEAR
					fillBlank(x, y)
				else
					@playBoard.cellMap[x][y].marker = openCell
					@playBoard.cellMap[x][y].visible = true
				end
				
			elsif cell == @@UNKNOWN && openCell == @@MINE
				@playBoard.cellMap[x][y].marker = openCell
				@playBoard.cellMap[x][y].visible = true
				@gameOver = true
			else
				return false
			end
			return true
		else
			return false
		end
	end

	# Função que verifica se a posição de entrada é válida para ser uma bandeira, se for, verifica o marcador no tabuleiro aberto
	# para saber se é uma mina, se for uma mina, salva o valor de minas na variável safeMines e transforma em bandeira. Caso já
	# seja uma bandeira, volta a mesma para a posição antiga.
	def flag(x, y)
		if @playBoard.validFlag(x, y)
			cell = @playBoard.cellMap[x][y]

			if cell.marker == @@UNKNOWN && @mineBoard.cellMap[x][y].marker == @@MINE
				@safeMines += 1
			elsif cell.marker == @@FLAG && @mineBoard.cellMap[x][y].marker == @@MINE
				@safeMines -= 1
			end
		
			if cell.marker == @@UNKNOWN
				cell.marker = @@FLAG
			elsif cell.marker == @@FLAG
				cell.marker = @@UNKNOWN
			end

			return true
		end
		return false
	end

	# Função que retorna o valor total de minas com bandeira.
	def getFlagged
		return @safeMines
	end

	# Função que verifica se o jogo continua rodando, caso ainda não tenha sido Game Over.
	def still_playing?
		if @gameOver
			return false
		end
		return true
	end

	# Função para verificar se o jogo foi ganho através de safeMines, caso todas as minas estejam com bandeira, o jogo foi ganho.
	def victory?
		if @safeMines == @numMines
			@gameOver = true
			return true
		end
		return false
	end

	# Função que retorna o tabuleiro do jogo, caso xray seja falso, retorna o mapa atual conforme o decorrer do jogo, caso xray seja
	# verdadeiro, então retorna o mapa totalmente revelado, ou seja, mineBoard, logo após ser adicionada as bandeiras.
	def board_state(xray: false)
		if xray

			@playBoard.cellMap.each do |cellRow|
				cellRow.each do |cell|
					if cell.marker == @@FLAG
						x, y = cell.x, cell.y
						@mineBoard.cellMap[x][y].marker = @@FLAG
					end
				end
			end
			return @mineBoard.board_state()
		else
			return @playBoard.board_state()
		end

	end

end



# ------------------------------------- PRINTERS -------------------------------------

# Os printers que irão imprimir o tabuleiro na tela, um mais simples e outro mais "bonito".

# Classe SimplePrinter - É a classe que cria um printer mais simples, esse printer exibe todas as células uma ao lado
# da outra, sem nenhuma divisória.
class SimplePrinter

	# Função que imprime o tabuleiro.
	def show(board_state)
		board_state.each do |col|
			col.each do |cell|
				print cell.marker
			end
			puts
		end
		puts
	end
end

# Classe PrettyPrinter - É a classe que cria um printer mais bonito, a saída é separa por espações e possui divisória nas bordas.
class PrettyPrinter

	# Função que imprime o tabuleiro.
	def show(board_state)
		board_state.each do |col|
			@count = 0
			print " "
			col.each do |cell|
				print " #{cell.marker}  "
				@count += 1
			end
			puts
			print " "
			print (("    ") * @count)
			puts
		end
		print (("----") * @count)
		puts
	end
end

# ----------------------------------- END PRINTERS -----------------------------------


# Função criada para começar o jogo, ao chamar a função, executa o jogo inteiro de acordo com os valores de entrada para largura e altura.
def startGame()
	width, height, numMines = 20, 20, 50
	game = Minesweeper.new(width, height, numMines)


	while game.still_playing?
		valid_move = game.play(rand(20), rand(20))
		valid_flag = game.flag(rand(20), rand(20))

		if valid_move or valid_flag
			printer = (rand > 0.5) ? SimplePrinter.new() : PrettyPrinter.new()
			printer.show(game.board_state())
		end
	end

	puts "Fim de Jogo!"
	if game.victory?
		puts "Você Venceu!"
	else
		puts "Você Perdeu!"
		puts "As minas eram: "
		puts "Quantidade de minas com bandeiras: #{game.getFlagged}"

		PrettyPrinter.new.show(game.board_state(xray: true))
	end
end

# Chama a função para executar o jogo.
startGame()