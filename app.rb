class App < Sinatra::Base

	#___________________NOTES_____________________
	#HUR GJORDE MAN SIDAN DYNAMISK SÅ ATT DEN LADDAR OLIKA PRODUKTER MED SAMMA LAYOUT?
	#___________________NOTES_____________________

	enable :sessions

	get('/register') do
		slim(:register)
	end

	get('/start') do
		db = SQLite3::Database.new("db/db.db")
		products = db.execute("SELECT * FROM products")
		slim(:start, locals:{products:products})
	end

	get('/saved_prod') do
		slim(:saved_prod)
	end
	
	get('/profile') do
		slim(:profile)
	end

	get('/') do
		slim(:start)
	end

	get('/cart') do
		slim(:cart)
	end

	get('/product') do
		slim(:product)
	end

	get('/signed_out') do
		slim(:signed_out)
	end

	post('/register') do
		db = SQLite3::Database.new('db/db.db')
		db.results_as_hash = true
		
		username = params["username"]
		password = params["password"]
		password_confirmation = params["confirm_password"]
		
		result = db.execute("SELECT id FROM users WHERE username=?", [username])

		if result.empty?
			if password == password_confirmation
				password_digest = BCrypt::Password.create(password)
				
				db.execute("INSERT INTO users(username, password_digest) VALUES (?,?)", [username, password_digest])
				redirect('/')
			else
				set_error("Passwords don't match")
				redirect('/error')
			end
		else
			set_error("Username already exists")
			redirect('/error')
		end

	end

	post('/login') do
		db = SQLite3::Database.new('db/db.db') #Länka SQLITE
		username = params["username"] # Hämtad från register.slim, input med name="username"
		password = params["password"]
		password_crypted = db.execute("SELECT password_digest FROM users WHERE username=?", [username])
		if password_crypted == []
			password_digest = nil
		else
			password_crypted = password_crypted[0][0] # första värdet, kollar på username, andra värden är password
			password_digest = BCrypt::Password.new(password_crypted) # "Dekryptar"
		end
		if password_digest == password # om lösenordet matchar
			result = db.execute("SELECT id FROM users WHERE username=?", [username]) #Hämta ID från konton
			session[:id] = result[0][0] # id
			session[:login] = true # Är inloggad
		else
			session[:login] = false # Är INTE inloggad
		end
		redirect('/home')
	end

	get('/profile/:user_id') do
		db = SQLite3::Database.new('db/db.db')
		user_id = session[:id].to_i
		if session[:login] == true #Om man har loggat in		
			begin
				products = db.execute('SELECT * IN saved_prod WHERE id=?', [user_id])
				user_info = db.execute('SELECT name AND user_info FROM users WHERE id=?', [user_id])
			rescue SQLite3::ConstraintException
				session[:message] = "You are not logged in"
				redirect("/error")
			end
		else
			session[:message] = "You are not logged in"
			redirect("/error")
		end

		slim(:profile, locals:{styles:styles})
	end

	post('/delete/:id') do
		db = SQLite3::Database.new('db/db.db')
		user_id = session[:id].to_i
		id = params[:id]
		db.execute("DELETE prod_id=? FROM saved_prod WHERE id=?", [id, user_id])
		redirect('/saved_prod')
	end

	post('fav/:prod_id')
		prod_id=params[:prod_id]
		user_id = session[:id].to_i
		db.execute("INSERT INTO saved_prod (user_id, prod_id) VALUES=(?,?)", [user_id, prod_id])
	end

	get('/error') do
		slim(:error, locals:{msg:session[:message]})
	end

	post('/logout') do
		session[:login] = false
		session[:id] = nil
		redirect('/signed_out')
	end

end           