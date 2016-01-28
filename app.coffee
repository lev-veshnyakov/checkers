# Игра в русские шашки 

# @author Лев Вешняков weshnjakow@mail.ru
 
# из-за недостатка времени:
 
# TODO: не реализована возможность задать движение шахматного коня
# TODO: не реализована возможность задать движение рокировки
# TODO: не реализована возможность запрета взятия фигур (напр. для угоков)
# TODO: не реализована возможность определения патовой ситуации
# TODO: сделать методы GameField.cells_between, GameField.figures_between 
	# и GameField.move_direction приватными
# TODO: код не может быть минифицирован из-за того, что явным образом не вызывается инжектор
# TODO: не учтена возможность для реализации клиент-серверной архитектуры
# TODO: не написаны тесты
 
 
angular.module('Models', [])
# направления движения фигур относительно своей стороны игрового поля
.value('_', new () ->
	@right = 'right'
	@left = 'left'
	@forward = 'forward'
	@back = 'back'
	@forward_right = 'forward_right'
	@forward_left = 'forward_left'
	@back_right = 'back_right'
	@back_left = 'back_left'
	# направление хода шахматного коня
	@knight = 'knight'
)
.factory('Figure', ()->

	# Базовый класс для всех фигур
	# @constructor
	# @param {number} color Цвет фигуры
	# @param {array} max_move_distance Расстояние хода фигуры
	# @param {array} max_capture_distance Максимальное расстояние за взятой фигурой, на которое может 
		# переместиться бъющая фигура (1 для простой шашки, 6 для дамки, 0 для шахматных фигур)
	# @param {array} move_directions Список допустимых направлений хода фигуры 
	# @param {array} capture_directions Список допустимых направлений боя фигуры 
	
	class Figure
		constructor: (@color='white', @max_move_distance, @max_capture_distance, 
					  @move_directions, @capture_directions)->
)

.factory('Man', (Figure, _)->
	
	# Модель пешки
	# @constructor
	class Man extends Figure
		constructor: (color) ->
			super(color, 1, 1, [_.forward_left, _.forward_right], 
				  [_.forward_left, _.forward_right, _.back_left, _.back_right]);
)

.factory('King', (Figure, _)->
	
	# Модель дамки
	# @constructor
	class King extends Figure
		constructor: (color) ->
			super(color, 8, 6, [_.forward_left, _.forward_right, _.back_left, _.back_right], 
					  [_.forward_left, _.forward_right, _.back_left, _.back_right]);
)

.factory('Timer', ($interval)->
	
	# Таймер
	# @constructor
	class Timer
		handle = null;
		constructor: () ->
			@time = new Date(0) 
		start: () ->
			handle = $interval ()=>
				@time = new Date(@time.getTime()+1000)
			, 1000
		stop: () ->
			$interval.cancel handle
		reset: () ->
			@stop()
			@time = new Date(0)
)
.factory('Player', (Timer)->
	
	# Модель игрока
	# @constructor
	# @param {string} name Имя игрока
	# @param {string} color Цвет фигур, за котрые играет
	# @param {number} scores Количество выйгранных партий
	class Player
		constructor: (@name, @color = 'white', @scores = 0) ->
			@timer = new Timer(0)
			# список захваченных за время партии фигур
			@captured_figures = []
)

.factory('GameField', (_, Figure)->
	
	# Модель игрового поля
	# @constructor
	# @param {number} game_field_size Размер игрового поля в одном направлении
	class GameField 
		constructor: (@game_field_size) ->
			# ссылка на список строк с ячееками игрового поля.
			# индексация строк начинается со стороны чёрных фигур.
			@cells = {}
			# создаём ячейки игрового поля
			for row in [1..game_field_size]
				# строки игрового поля также доступны как поля экземпляра 
				# GameField по числовым ключам от 1 до n
				@[row] = @cells[row] = {}
				for col in [1..game_field_size]
					@[row][col] = @cells[row][col] = 
						color: color(row, col),
						figure: null, 
						row: row, 
						col: col
		
		# определяет цвет ячейки игрового поля по индексам
		# используется при инициализации поля
		# @private
		# @return {string}
		color = (row, col) ->
			if row % 2 == 0
				if col % 2 != 0
					return 'black';
			else
				if col % 2 == 0
					return 'black';
			return 'white';
		
		# определяет расстояние между начальной и конечной ячейками хода
		# @private
		# @return {object} объект с расстояниями по вертикали и горизонтали и наибольшее из них
		move_distance = (cell_from, cell_to) ->
			vertical = Math.max(cell_from.row, cell_to.row) - Math.min(cell_from.row, cell_to.row)
			horizontal = Math.max(cell_from.col, cell_to.col) - Math.min(cell_from.col, cell_to.col)
			return {vertical: vertical, horizontal: horizontal, max: Math.max(vertical, horizontal)}
		
		# возвращает список ячеек, лежащих между начальной и конечной ячейками хода
		# @return {array} 
		cells_between: (cell_from, cell_to) ->
			arr = []
			i = 0
			distance = move_distance(cell_from, cell_to)
			if not distance.vertical
				for col in [cell_from.col..cell_to.col]
					cell = @[cell_from.row][col]
					if cell != cell_from and cell != cell_to
						arr.push(cell)
			else if not distance.horizontal
				for row in [cell_from.row..cell_to.row]
					cell = @[row][cell_from.col]
					if cell != cell_from and cell != cell_to
						arr.push(cell)
			else 
				for col in [cell_from.col..cell_to.col]
					if cell_from.row < cell_to.row
						cell = @[cell_from.row + i++][col]
						if cell != cell_from and cell != cell_to
							arr.push(cell)
					else
						cell = @[cell_from.row + i--][col]
						if cell != cell_from and cell != cell_to
							arr.push(cell)
					
			return arr
		
		# возвращает список фигур, лежащих между начальной и конечной ячейками хода
		# @return {array} 		
		figures_between: (cells_between) ->
			result = 
				white: []
				black: []
			for cell in cells_between
				if cell.figure
					if cell.figure.color == 'white'
						result.white.push(cell.figure)
					else
						result.black.push(cell.figure)
			return result		
		
		# возвращает направление хода фигуры
		# @return {string} 
		move_direction: (cell_from, cell_to) ->
			figure = cell_from.figure
			distance = move_distance(cell_from, cell_to)
			# если двигали по диагонали
			if distance.vertical and distance.horizontal
				if figure.color == 'white'
					if cell_from.row < cell_to.row
						if cell_from.col < cell_to.col
							return _.back_right;
						else
							return _.back_left
					else
						if cell_from.col < cell_to.col
							return _.forward_right
						else
							return _.forward_left
				else 
					if cell_from.row < cell_to.row
						if cell_from.col < cell_to.col
							return _.forward_right
						else
							return _.forward_left
					else
						if cell_from.col < cell_to.col
							return _.back_right
						else
							return _.back_left
			# если двигали по вертикали
			else if distance.vertical
				if figure.color == 'white'
					if cell_from.row < cell_to.row
						return _.back
					else 
						return _.forward
				else
					if cell_from.row < cell_to.row
						return _.forward
					else 
						return _.back
			else if distance.horizontal
				if figure.color == 'white'
					if cell_from.col < cell_to.col
						return _.right
					else 
						return _.left
				else
					if cell_from.col < cell_to.col
						return _.left
					else 
						return _.right
		
		# основной метод класса. осуществляет проверку допустимости хода, ход и взятие фигур
		# @param {Player} player Текущий игрок
		# @param {object} cell_from Начальная ячейка
		# @param {object} cell_to Конечная ячейка
		# @param {boolean} fake Если true, то фигуры остаются на своих местах. Используется для проверки 
			# результата хода без самого хода
		# @return {mixed} если был выполнен бой, то возвращает битую фигуру, если простой ход - то true.
			# если ход недопустимый, то возвращает false
		figure_move: (player, cell_from, cell_to, fake) ->
			figure = cell_from.figure
			capture = () ->
				if not fake
					cell_to.figure = cell_from.figure
					cell_from.figure = null;
				for cell in cells_between
					if cell.figure
						captured_figure = cell.figure
						if not fake
							cell.figure = null;
						return captured_figure
			# если двигали свою фигуру
			if figure and figure.color == player.color
				# расстояние, на которое пердвинули
				distance = move_distance(cell_from, cell_to)
				# если та же самая ячейка
				if cell_from == cell_to
					return no;
				if distance.vertical and distance.horizontal 
					if distance.vertical != distance.horizontal and _.knight not in figure.move_directions
						return no;
				# направление движения
				move_direction = @move_direction(cell_from, cell_to)
				# пересечённые ячейки
				cells_between = @cells_between(cell_from, cell_to)
				# пересечённые фигуры
				figures_between = @figures_between(cells_between)
				# если конечная ячейка не пустая
				if cell_to.figure
					# если конечная занята своей
					if cell_to.figure.color == player.color
						return no;
					# если на пути стоит фигура
					else if figures_between.black.length or figures_between.white.length
						return no;
					# если бъём как в шахматах, вставая на место бытой
					else if figure.max_capture_distance == 0
						# направление хода совпадает с направлениями боя
						if move_direction in figure.capture_directions
							# бъём фигуру
							return capture()
					else
						return no;
				# если на пути стоит своя фигура
				if figures_between[figure.color].length > 0
					return no;
				# если на пути стоят несколько чужих фигур
				else if figures_between[if figure.color == 'white' then 'black' else 'white'].length > 1
					return no;
				else if figures_between[if figure.color == 'white' then 'black' else 'white'].length == 1
					# расстояние от начальной ячейки для чужой фигуры на пути
					# TODO: вынести в функцию
					figure_between_distance = 1;
					i = 1
					for cell in cells_between
						if cell.figure
							figure_between_distance = i
						i++	
					# если конечная ячейка не дальше битой на расстояние боя и битая ячейка не дальше расстояния хода
					if distance.max - figure_between_distance <= figure.max_capture_distance and figure_between_distance <= figure.max_move_distance
						# направление движения совпадает с направлениями боя
						if move_direction in figure.capture_directions
							return capture()
					else
						return no;
				# расстояние хода больше допустимого
				else if distance.max > figure.max_move_distance
					return no;
				# недопустимое направление хода
				if move_direction not in figure.move_directions
					return no;
				# переносим фигуру
				if not fake	
					cell_to.figure = cell_from.figure
					cell_from.figure = null;
				return yes;
			return no;
		
		# осуществляет проверку возможности любого допустимого хода выбранной фигуры
		# @param {Player} player Текущий игрок
		# @param {object} cell_from Ячейка с проверяемой фигурой
		# @param {object} capture Если true, то товеряет возможность только боевого хода
		# @return {boolean}
		can_move: (player, cell_from, capture = false) ->
			figure = cell_from.figure
			for n, row of @.cells
				for n, cell of row
					if not cell.figure or cell.figure.color != figure.color
						result = @figure_move(player, cell_from, cell, yes)
						if capture
							if result instanceof Figure
								return yes;
						else 
							if result
								return yes;
							
			return no;
	
		# осуществляет проверку возможности любого допустимого боевого хода выбранной фигурой
		# @param {Player} player Текущий игрок
		# @param {object} cell_from Ячейка с проверяемой фигурой
		# @return {boolean}
		can_capture: (player, cell_from) ->
			return @can_move(player, cell_from, yes)
			
		# осуществляет проверку возможности любого боевого хода хотя бы одной из фигур игрока
		# @param {Player} player Текущий игрок
		# @param {object} cell_from Ячейка с проверяемой фигурой
		# @return {boolean}
		can_capture_any: (player) ->
			for n, row of @.cells
				for n, cell of row
					if cell.figure and cell.figure.color == player.color
						if @can_capture(player, cell)
							return yes;
			return no;
)


angular.module('InitialPositionFactories', ['Models'])
.factory('InitialPositionFactory', (GameField)->
	
	# Абстрактная фабрика по созданию игрового поля и расстановке фигур
	# @constructor 
	# @return {GameField} Игровое поле 
	class InitialPositionFactory
		constructor: (game_field_size)->
			@game_field = new GameField(game_field_size)
		
		# размещает фигуру в ячейке
		place_figure: (figure, row, col) ->
			@game_field[row][col].figure = figure
)
.factory('CheckersInitialPositionFactory', (InitialPositionFactory, Man)->
	
	# Конкретная фабрика для игры в шашки
	# @constructor 
	# @return {GameField} Игровое поле 
	class CheckersInitialPositionFactory extends InitialPositionFactory
		constructor: (game_field_size = 8) ->
			super game_field_size
			for row in [1,2,3,6,7,8]
				for col in [1..game_field_size]
					if @game_field[row][col].color == 'black'
						@place_figure(new Man('black' if 1 <= row <=3), row, col) 
			return @game_field
)

angular.module('Application', ['InitialPositionFactories'])
.controller('GameController', ($scope, Figure, Man, CheckersInitialPositionFactory, Player, King) ->
	
	$scope.players = [new Player(localStorage['player1_name'] ? 'Игрок 1', 'white', localStorage['player1_scores'] ? 0), 
					  new Player(localStorage['player2_name'] ? 'Игрок 2', 'black', localStorage['player2_scores'] ? 0)]
	# создаём и заполняем игровое поле
	$scope.game_field = new CheckersInitialPositionFactory
	$scope.selected_cell = null;
	$scope.game_state = 'stopped'
	
	$scope.start = () ->
		$scope.current_player = $scope.players[0];
		$scope.current_player.timer.start()
		$scope.game_state = 'running'
		localStorage['player1_name'] = $scope.players[0].name
		localStorage['player2_name'] = $scope.players[1].name
		$scope.message = null;
	
	$scope.stop = () ->
		$scope.current_player = null;
		for player in $scope.players
			player.timer.reset()
			player.captured_figures = []
		$scope.game_state = 'stopped'
		# пересоздаём игровое поле
		$scope.game_field = new CheckersInitialPositionFactory
		$scope.message = null;
		
	$scope.surrender = () ->
		# нельзя сдаться, когда висит сообщение о победе
		if $scope.game_state == 'running' and not $scope.message
			if $scope.current_player == $scope.players[0]
				$scope.players[1].scores++
				localStorage['player1_scores'] = $scope.players[0].scores
			else
				$scope.players[0].scores++
				localStorage['player2_scores'] = $scope.players[1].scores
			$scope.stop()
	
	$scope.cell_click = (cell) ->
		if not $scope.selected_cell
			# выбираем ячейку со своей фигурой
			if cell.figure and cell.figure.color == $scope.current_player.color
				$scope.selected_cell = cell
		else 
			# если есть возможность взятия любой фигуры противника запрещаем обычный ход
			if $scope.game_field.can_capture_any($scope.current_player) 
				if $scope.game_field.figure_move($scope.current_player, $scope.selected_cell, cell, yes) ==	 yes
					$scope.selected_cell = null;
					return
			
			# если ход или бой выполнен
			if result = $scope.game_field.figure_move($scope.current_player, $scope.selected_cell, cell)
				# пешку, дошедшую до последней горизонтали превращаем в дамку
				if cell.figure.color == 'white' and cell.row == 1 or cell.figure.color == 'black' and cell.row == 8
					cell.figure = new King(cell.figure.color)
				# если выполнен бой
				if result instanceof Figure
					$scope.current_player.captured_figures.push(result)
					# условие завершения партии - все фигуры противника биты
					if $scope.current_player.captured_figures.length == 12
						for player in $scope.players
							player.timer.stop()
						if $scope.current_player == $scope.players[0]
							$scope.players[0].scores++
							localStorage['player1_scores'] = $scope.players[0].scores
						else
							$scope.players[1].scores++
							localStorage['player2_scores'] = $scope.players[1].scores
						$scope.message = "Игрок #{$scope.current_player.name} победил!";
						return
					# если у сходившей фигуры есть возможность ещё одного взятия то не передаём ход другому игроку
					if $scope.game_field.can_capture($scope.current_player, cell)
						$scope.selected_cell = cell
						return
				$scope.current_player.timer.stop()
				# меняем текущего игрока
				$scope.current_player = if $scope.current_player == $scope.players[0] then $scope.players[1] else $scope.players[0];
				$scope.current_player.timer.start()
			$scope.selected_cell = null;
)