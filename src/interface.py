import sys
from PyQt5.QtWidgets import QApplication, QWidget, QPushButton
from PyQt5.QtCore import QCoreApplication
from random import randint

class octoPilot(QWidget):
    def __init__(self):
        super().__init__()
        self.initUi()

    def initUi(self):
        self.setGeometry(300,300,300,200)
        self.setWindowTitle("жопка")
        
        qbtn = QPushButton('жопа', self)
        qbtn.move(randint(1, 100), 100)
        qbtn.clicked.connect(QCoreApplication.instance().quit)

        qbtn = QPushButton('пися', self)
        qbtn.move(randint(1, 100), 100)
        qbtn.clicked.connect(QCoreApplication.instance().quit)


        
        
        self.show()

if __name__ == '__main__':
    app = QApplication(sys.argv)
    ex = octoPilot()
    sys.exit(app.exec_())

    btn = QPushButton('Button', self)
