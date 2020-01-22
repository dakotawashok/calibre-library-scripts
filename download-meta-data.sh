#!/bin/bash

echo "Running Meta-Data download script..."
echo "To get a list of books, run calibredb list --with-library=/mnt/pinas_01/calibre-library..."
echo ""

read -p "Enter the id of the book you'd like to download meta-data for:  " book_id

echo "Current meta-data: "
meta_data=`calibredb show_metadata $book_id --with-library=/mnt/pinas_01/calibre-library`
echo "$meta_data"

read -p "Do you have the ISBN and want to use that instead? (y/n): " isbn
if [ "$isbn" == "y" ]
then
	read -p "Enter the ISBN: " isbn
else 
	isbn=""
	read -p "Would you like to overwrite the author when searching? (y/n): " overwrite_author
	if [ "$overwrite_author" == "y" ]
	then
		read -p "Enter the author name: " author
	else 
		author=`echo "$meta_data" | grep "Author(s)" | sed 's|Author(s)           : ||'`
	fi

	read -p "Would you like to overwrite the title when searching? (y/n): " overwrite_title
	if [ "$overwrite_title" == "y" ]
	then
		read -p "Enter the title name: " title
	else 
		title=`echo "$meta_data" | grep "Title  " | sed 's|Title               : ||'`
	fi
fi


if [ -z "$isbn" ]
then
	echo "Attempting meta-data download for title: $title and author: $author"
	new_meta_data=`fetch-ebook-metadata -a $author -t $title`
	echo "$new_meta_data" > "./$title.opf"
	cat "./$title.opf"
else
	echo "Attempting meta-data download with ISBN: $isbn"
	new_meta_data=`fetch-ebook-metadata -i $isbn`
	echo "$new_meta_data" > "./$title.opf"
	cat "./$title.opf"
fi

echo "Succes!!"
read -p "Would you like to use this meta-data? (y/n): " replace_meta_data
if [ "$replace_meta_data" == "y" ]
then
	echo "Replacing old meta-data with the new meta-data..."
	if [ -z "$isbn" ]
	then
		new_meta_data_file=`fetch-ebook-metadata -a $author -t $title -o`
		echo "$new_meta_data_file" > "./$title.opf"
	else
		new_meta_data_file=`fetch-ebook-metadata -i $isbn -o`
		echo "$new_meta_data_file" > "./$title.opf"
	fi
	
	set_meta_data=`calibredb set_metadata --with-library=/mnt/pinas_01/calibre-library $book_id "./$title.opf"`
	if [ $? -eq 0 ]
	then
		echo "Successfully replace the meta-data!"
		exit 0;
	else
		echo "Error with replacing meta-data..."
		exit 1;
	fi
else 
	echo "Okay! Exiting program..."
	exit 0
fi
