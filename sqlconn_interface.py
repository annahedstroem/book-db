
from tkinter import *
import pprint
import time
from tkinter import messagebox
import datetime
import re
import os
import psycopg2
from psycopg2 import sql
from datetime import *
import psycopg2.extensions

conn = psycopg2.connect("host=localhost dbname=db")
cur = conn.cursor()

class Connect_Database():

    def __init__(self, host, dbname, user, password):
        conn_string = "host='"+host+"' dbname='"+dbname+"' user='"+user+"' password='"+password+"'"
        self.connection = psycopg2.connect(conn_string)
        self.cursor = self.connection.cursor()

    def select(self, command):
        self.cursor.execute(command)
        return self.cursor.fetchall()

class Booking_Details():
    def __init__(self, master):
        self.master = master
        self.frame = Frame(master, width=55, height=10)

        master.wm_title("")

        self.label_available_rooms = Label(self.frame, text="Choose between available rooms and facilities.")
        self.label_available_rooms.grid(row=1, column=0)

        self.available_rooms = Listbox(self.frame, selectmode=SINGLE)
        self.available_rooms.config(exportselection=False)
        self.available_rooms.config(width=55, height=25)
        self.available_rooms.bind("<<ListBoxSelect>>", self.choose_room)
        self.available_rooms.grid(row=10, column=0)

        self.go_back_buttom = Button(self.frame, text="Go back", command=self.go_back)
        self.go_back_buttom.grid(row=0, column=0)
        self.OK_buttom = Button(self.frame, text="OK", command=self.choose_room)
        self.OK_buttom.grid(row=3, column=0)

        #cur.execute("SELECT * FROM current_bookings WHERE booking_timing != ANY(%s);", (self.requested_time,))

        cur.execute("SELECT booking_timing FROM current_bookings")
        self.booking_timing = cur.fetchall()
        self.booking_timing = self.booking_timing[-1]
        self.booking_timing = str(self.booking_timing[0])
        #print(self.booking_timing)


        cur.execute("SELECT booking_date FROM current_bookings")
        self.booking_date = cur.fetchall()
        self.booking_date = self.booking_date[-1]
        self.booking_date = str(self.booking_date[0])
        #print(self.booking_date)
        
        sql = "SELECT resources.room_id, resources.room_name, resources.room_facilities FROM resources" #LEFT OUTER JOIN current_bookings ON resources.room_id = current_bookings.room_id WHERE CAST(booking_timing AS TIME) != %s AND CAST(booking_date AS DATE) != %s;"

        cur.execute(sql, (self.booking_timing, self.booking_date))
        self.rooms = cur.fetchall()

        column = 0
        for i in self.rooms:
            self.available_rooms.insert(END, i)
            column += 1

    def show(self):
        self.frame.grid(row=0, column=0)

    def hide(self):
        self.frame.grid_forget()

    def go_back(self):
        window = Show_Times(self.master)
        self.hide()
        window.show()

    def choose_room(self):
        selections = self.available_rooms.curselection()
        value = self.available_rooms.get(selections)
        selections = [int(x) + 1 for x in selections]
        #print("room index:", selections, ": '%s'" % str(value))

        # Go to next window
        window = Personal_Details(self.master)
        self.hide()
        window.show()


class Personal_Details():
    def __init__(self, master):
        self.master = master
        self.frame = Frame(master, width=55, height=10)
        master.wm_title("")

        self.label_persons = Label(self.frame, text="Select your name and project team.")
        self.label_persons.grid(row=1, column=0)

        self.all_persons = Listbox(self.frame, selectmode=SINGLE)
        self.all_persons.config(exportselection=False)
        self.all_persons.config(width=55, height=10)
        self.all_persons.bind("<<ListBoxSelect>>", self.choose_name)
        self.all_persons.grid(row=10, column=0)

        self.all_teams = Listbox(self.frame, selectmode=SINGLE)
        self.all_teams.config(exportselection=False)
        self.all_teams.config(width=55, height=10)
        self.all_teams.bind("<<ListBoxSelect>>", self.choose_team)
        self.all_teams.grid(row=20, column=0)

        self.go_back_buttom = Button(self.frame, text="Go back", command=self.go_back)
        self.go_back_buttom.grid(row=0, column=0)
        self.confirm_booking_buttom = Button(self.frame, text="Confirm Name", command=self.choose_name)
        self.confirm_booking_buttom.grid(row=14, column=0)
        self.confirm_booking_buttom = Button(self.frame, text="Confirm Team", command=self.choose_team)
        self.confirm_booking_buttom.grid(row=40, column=0)

        cur.execute("SELECT staff_id, fname, lname FROM person")
        self.person = cur.fetchall()

        column = 0
        for i in self.person:
            self.all_persons.insert(END, i)
            column += 1

        cur.execute("SELECT team_id, team_name FROM team")
        self.team = cur.fetchall()

        column1 = 0
        for i in self.team:
            self.all_teams.insert(END, i)
            column1 += 1

    def show(self):
        self.frame.grid(row=0, column=0)

    def hide(self):
        self.frame.grid_forget()

    def go_back(self):
        window = Booking_Details(self.master)
        self.hide()
        window.show()

    def choose_name(self):
        self.name_selections = self.all_persons.curselection()
        self.staff_id = self.all_persons.get(self.name_selections[0])
        self.name_selections = [int(x) + 1 for x in self.name_selections]
        #print("person index:", self.name_selections, ": '%s'" % self.staff_id[0])
        self.staff_id = str(self.staff_id[0])

        cur.execute("SELECT booking_id FROM current_bookings ORDER BY booking_id ASC")
        self.id = cur.fetchall()[-1]
        id = str(self.id[0])

        update_staff_id = """UPDATE current_bookings SET staff_id = %s WHERE booking_id = %s"""
        cur.execute(update_staff_id, (self.staff_id, id))
        conn.commit()

    def choose_team(self):
        self.team_selections = self.all_teams.curselection()
        self.team_id = self.all_teams.get(self.team_selections[0])
        self.team_selections = [int(x) + 1 for x in self.team_selections]
        #print("team index:", self.team_selections, ": '%s'" % self.team_id[0])
        self.team_id = str(self.team_id[0])

        cur.execute("SELECT booking_id FROM current_bookings ORDER BY booking_id ASC")
        self.id = cur.fetchall()[-1]
        id = str(self.id[0])

        update_team_id = "UPDATE current_bookings SET team_id = %s WHERE booking_id = %s"
        cur.execute(update_team_id, (self.team_id, id))
        conn.commit()

        # Go to next window
        window = Select_Participants(self.master)
        self.hide()
        window.show()


class Select_Participants():
    def __init__(self, master):
        self.master = master
        self.frame = Frame(master, width=55, height=10)
        self.selections = None
        self.current_id = []
        master.wm_title("")

        self.label_available_persons = Label(self.frame, text="Who will join you on the meeting? Select participants.")
        self.label_available_persons.grid(row=1, column=0)

        self.available_persons = Listbox(self.frame, selectmode=EXTENDED)
        self.available_persons.config(exportselection=False)
        self.available_persons.config(width=55, height=25)
        self.available_persons.bind("<<ListBoxSelect>>", self.choose_participants)
        self.available_persons.grid(row=10, column=0)

        self.go_back_buttom = Button(self.frame, text="Go back", command=self.go_back)
        self.go_back_buttom.grid(row=0, column=0)

        self.OK_buttom = Button(self.frame, text="Confirm you booking", command=self.choose_participants)
        self.OK_buttom.grid(row=26, column=0)

        cur.execute("SELECT * FROM person")
        self.persons = cur.fetchall()

        column = 0
        for i in self.persons:
            self.available_persons.insert(END, i)
            column += 1

    def show(self):
        self.frame.grid(row=0, column=0)

    def hide(self):
        self.frame.grid_forget()

    def go_back(self):
        window = Personal_Details(self.master)
        self.hide()
        window.show()

    def choose_participants(self):
        self.selections = self.available_persons.curselection()
        self.selections = [int(x) + 1 for x in self.selections]
        print("participants id:", self.selections)

        cur.execute("SELECT fname, lname FROM person WHERE staff_id = ANY(%s);", (self.selections,))
        conn.commit()
        self.participants_names = cur.fetchall()

        cur.execute("SELECT booking_id FROM current_bookings ORDER BY booking_id ASC")
        self.id = cur.fetchall()[-1]
        id = str(self.id[0])

        cur.execute("UPDATE current_bookings SET participants = %s WHERE booking_id = %s;", (self.participants_names[:], (id)))
        conn.commit()

        cur.execute(sql.SQL("DELETE FROM current_bookings WHERE participants = 'NULL'"))
        conn.commit()

        window = Welcome_Window(self.master)
        self.hide()
        window.show()


class Show_Times():
    def __init__(self, master):
        self.master = master
        self.frame = Frame(master, width=55, height=10)
        self.selections = None
        self.current_id = []
        master.wm_title("")

        self.label_available_times = Label(self.frame, text="What time do you want your booking? Specify start hour.")
        self.label_available_times.grid(row=1, column=0)

        self.available_times = Listbox(self.frame, selectmode=SINGLE)
        self.available_times.config(exportselection=False)
        self.available_times.config(width=55, height=25)
        self.available_times.bind("<<ListBoxSelect>>", self.choose_time)
        self.available_times.grid(row=10, column=0)

        self.go_back_buttom = Button(self.frame, text="Go back", command=self.go_back)
        self.go_back_buttom.grid(row=0, column=0)

        self.OK_buttom = Button(self.frame, text="OK", command=self.choose_time)
        self.OK_buttom.grid(row=3, column=0)

        cur.execute("SELECT times FROM available_times")
        self.times = cur.fetchall()

        column = 0
        for i in self.times:
            self.available_times.insert(END, i)
            column += 1

    # Todo. If no available rooms add a loop that tells the user that.

    def show(self):
        self.frame.grid(row=0, column=0)

    def hide(self):
        self.frame.grid_forget()

    def go_back(self):
        window = Show_Dates(self.master)
        self.hide()
        window.show()

    def choose_time(self):
        self.selections = self.available_times.curselection()
        self.start_time = self.available_times.get(self.selections[0])
        self.selections = [int(x) + 1 for x in self.selections]
        #print("time index:", self.selections, ": '%s'" % self.start_time[0])
        self.start_time = str(self.start_time[0])

        cur.execute("SELECT booking_id FROM current_bookings ORDER BY booking_id ASC")
        self.id = cur.fetchall()[-1]
        id = str(self.id[0])

        sql = "UPDATE current_bookings SET booking_timing = %s WHERE booking_id = %s"
        cur.execute(sql, (self.start_time, id))
        conn.commit()

        window = Booking_Details(self.master)
        self.hide()
        window.show()


class Show_Dates():
    def __init__(self, master):
        self.master = master
        self.frame = Frame(master, width=55, height=10)
        self.start_date = "1999-01-01"
        self.start_time = "00:00:00"
        self.staff_id = 1
        self.team_id = 1
        self.room_id = 1
        self.participants = "NULL"
        self.selections = None
        self.current_id = []
        master.wm_title("")

        self.label_available_dates= Label(self.frame, text="When do you need a room? Specify date to proceed with booking.")
        self.label_available_dates.grid(row=1, column=0)

        self.available_dates = Listbox(self.frame, selectmode=SINGLE)
        self.available_dates.config(exportselection=False)
        self.available_dates.config(width=55, height=25)
        self.available_dates.bind("<<ListBoxSelect>>", self.choose_date)
        self.available_dates.grid(row=10, column=0)

        self.go_back_buttom = Button(self.frame, text="Go back", command=self.go_back)
        self.go_back_buttom.grid(row=0, column=0)

        self.OK_buttom = Button(self.frame, text="OK", command=self.choose_date)
        self.OK_buttom.grid(row=3, column=0)

        cur.execute("SELECT dates FROM available_dates")
        self.dates = cur.fetchall()

        column = 0
        for i in self.dates:
            self.available_dates.insert(END, i)
            column += 1

    # Todo. If no available rooms add a loop that tells the user that.

    def show(self):
        self.frame.grid(row=0, column=0)

    def hide(self):
        self.frame.grid_forget()

    def go_back(self):
        window = Welcome_Window(self.master)
        self.hide()
        window.show()

    def choose_date(self):
        self.selections = self.available_dates.curselection()
        self.start_date = self.available_dates.get(self.selections[0])
        self.selections = [int(x) + 1 for x in self.selections]
        #print("date index:", self.selections, ": '%s'" % self.start_date[0])
        self.start_date = str(self.start_date[0])

        self.current_id = cur.execute("SELECT booking_id FROM current_bookings ORDER BY booking_id ASC")
        self.id = cur.fetchall()[-1]
        self.id = str(self.id[0]+1)

        cur.execute("INSERT INTO current_bookings VALUES (%s,%s, %s, %s, %s, %s, %s)", (self.id, self.start_time, self.start_date, self.staff_id, self.team_id, self.room_id, self.participants))
        conn.commit()

        window = Show_Times(self.master)
        self.hide()
        window.show()


class Personal_Details_Remove():
    def __init__(self, master):
        self.master = master
        self.frame = Frame(master, width=55, height=10)

        master.wm_title("")

        self.label_persons = Label(self.frame, text="Select your name.")
        self.label_persons.grid(row=1, column=0)

        self.all_persons = Listbox(self.frame, selectmode=SINGLE)
        self.all_persons.config(exportselection=False)
        self.all_persons.config(width=55, height=10)
        self.all_persons.bind("<<ListBoxSelect>>", self.choose_name)
        self.all_persons.grid(row=10, column=0)

        self.person_times = Listbox(self.frame, selectmode=SINGLE)
        self.person_times.config(exportselection=False)
        self.person_times.config(width=55, height=10)
        self.person_times.bind("<<ListBoxSelect>>", self.choose_time)
        self.person_times.grid(row=25, column=0)

        self.go_back_buttom = Button(self.frame, text="Go back", command=self.go_back)
        self.go_back_buttom.grid(row=0, column=0)
        self.confirm_booking_buttom = Button(self.frame, text="Confirm Name", command=self.choose_name)
        self.confirm_booking_buttom.grid(row=4, column=0)
        self.confirm_time_buttom = Button(self.frame, text="Choose Time", command=self.choose_time)
        self.confirm_time_buttom.grid(row=22, column=0)

        cur.execute("SELECT fname, lname, staff_id FROM person")
        self.person = cur.fetchall()

        column = 0
        for i in self.person:
            self.all_persons.insert(END, i)
            column += 1

    def show(self):
        self.frame.grid(row=0, column=0)

    def hide(self):
        self.frame.grid_forget()

    def go_back(self):
        window = Welcome_Window(self.master)
        self.hide()
        window.show()

    def choose_name(self):
        selections = self.all_persons.curselection()
        person_id = self.all_persons.get(selections[0])
        selections = [int(x) + 1 for x in selections]
        #print("person index:", selections, ": '%s'" % person_id[2])
        person_id = person_id[2]

        cur.execute(" SELECT booking_id, booking_timing, booking_date FROM current_bookings WHERE staff_id = %s",
                    (person_id,))

        self.times = cur.fetchall()
        column = 0
        for i in self.times:
            self.person_times.insert(END, i)
            column += 1

    def choose_time(self):
        self.selections = self.person_times.curselection()
        self.start_time = self.person_times.get(self.selections[0])
        self.selections = [int(x) + 1 for x in self.selections]
        #print("time index:", self.selections, ": '%s'" % self.start_time[1])
        self.start_time = str(self.start_time[1])

        cur.execute(
            sql.SQL("DELETE FROM current_bookings WHERE booking_timing = (%s)"),
            [self.start_time])
        conn.commit()

        window = DeletionView(self.master)
        self.hide()
        window.show()


class DeletionView():
    def __init__(self, master):
        self.master = master
        self.frame = Frame(master, width=55, height=10)
        master.wm_title("")
        self.label_available_times = Label(self.frame, text="Your booking has succesfully been deleted!")
        self.label_available_times.grid(row=0, column=0)
        self.label_available_times.pack()
        self.label_available_times.config(width=55, height=10)

        self.go_back_buttom = Button(self.frame, text="Go back to Main Menu", command=self.go_back)
        self.go_back_buttom.grid(row=1, column=0)
        self.go_back_buttom.pack()

    def show(self):
        self.frame.grid(row=0, column=0)

    def hide(self):
        self.frame.grid_forget()

    def go_back(self):
        window = Welcome_Window(self.master)
        self.hide()
        window.show()


class Welcome_Window():
    def __init__(self, master):
        self.master = master
        self.frame = Frame(self.master, width=55, height=10)

        master.wm_title("")
        self.start_label = Label(self.frame, text="Choose your action.")
        self.start_label.grid(row=0, column=1)
        self.start_label.pack()
        self.start_label.config(width=55, height=10)

        self.book_buttom = Button(self.frame, text="Book Room", command=self.book_room)
        self.book_buttom.grid(row=1, column=0)
        self.book_buttom.pack()

        self.remove_buttom = Button(self.frame, text="Remove Room", command=self.remove_room)
        self.remove_buttom.grid(row=1, column=2)
        self.remove_buttom.pack()

    def show(self):
        self.frame.grid(row=0, column=0)

    def hide(self):
        self.frame.grid_forget()
    
    def book_room(self):
        window = Show_Dates(self.master)
        self.hide()
        window.show()

    def remove_room(self):
        window = Personal_Details_Remove(self.master)
        self.hide()
        window.show()


def main():
    root = Tk()
    root.geometry("500x510")
    welcome = Welcome_Window(root)
    welcome.show()
    root.mainloop()
    cur.close()
    conn.close()

if __name__ == "__main__":
    db = Connect_Database("localhost", "db", "name", "pw")
    main()



