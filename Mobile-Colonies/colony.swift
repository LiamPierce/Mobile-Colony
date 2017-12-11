//
//  colony.swift
//  Mobile-Colonies
//
//  Created by Liam Pierce on 11/27/17.
//  Copyright © 2017 Virtual Earth. All rights reserved.
//
import Foundation

struct Cell{
    let X:Int;
    let Y:Int;
    
    init(_ X: Int,_ Y: Int){
        self.X = X;
        self.Y = Y;
    }
    
    init(_ X: Int, _ Y: Int, size: Int,_ wrapping:Bool?=nil){
        print(size);
        if wrapping != nil && wrapping! == true && size != 0 || wrapping == nil && size != 1001 && size > 1{
            if X < 0{
                self.X = size - (abs(X) % size)
            }else{
                self.X = X % size
            }
            
            if Y < 0{
                self.Y = (size) - (abs(Y) % size)
            }else{
                self.Y = Y % size;
            }
        }else{
            self.X = X;
            self.Y = Y;
        }
    }
    
    static func getColonyLoc(_ X:Int, _ Y:Int, size:Int)->(Double,Double){
        if (size != 1001 && size > 1){
            var xCol = 0.0;
            var yCol = 0.0;
            
            if X < 0{
                xCol = (Double(X) / Double(size))
            }else{
                xCol = (Double(X) / Double(size))
            }
            
            if Y < 0{
                yCol = (Double(Y) / Double(size))
            }else{
                yCol = Double(Y) / Double(size);
            }
            
            return (xCol,yCol);
        }
        return (0,0);
    }
    
    var description: String {
        return String(X) + ":" + String(Y);
    }
    
    func transform(_ x:Int,_ y:Int)->Cell{
        return Cell(X + x,Y + y);
    }
}

struct Bound : CustomStringConvertible{
    let lBound : Cell;
    let rBound : Cell;
    
    var description:String{
        return "Lower Left Bound : \(lBound), Upper Right Bound : \(rBound)"
    }
}

func == (lhs: Cell, rhs: Cell) -> Bool {
    return lhs.X == rhs.X && lhs.Y == rhs.Y;
}

extension Cell: Hashable{
    var hashValue: Int{ return X.hashValue ^ Y.hashValue &* 16777619 }
}

class Colony: CustomStringConvertible{
    
    var wrapping = true;
    var Cells = Set<Cell>();
    var numberLivingCells:Int{ return Cells.count; }
    var size: Int = 1;
    
    static var numberFormatter:NumberFormatter = {
        let formatter = NumberFormatter()
        return formatter;
    }()
    
    static func interpret(name:String,fromDiagram colony:String)->ColonyData?{
        var base = ColonyData(name:name,size:0,colony:Colony(false));
        
        let lines = colony.split(separator: "\n").map{ String($0) };
        
        let width  = lines.map{ $0.count }.max()!;
        let height = lines.count;
        
        base.size = max(width, height);
        
        for (yIndex,line) in lines.enumerated(){
            for (xIndex,character) in line.enumerated(){
                if character == "*" || character == "O"{
                    base.colony.setCellAlive(X:xIndex + 1,Y:yIndex + 1)
                }
            }
        }
        
        return base;
    }
    
    static func interpret(name:String, fromRLE colony: String)->ColonyData?{
        //Found out that the massive "breeder" file this was for was in high life, not just life.
        var base = ColonyData(name:name,size:0,colony:Colony(false));
        
        var xPos = 1;
        var yPos = 1;
        
        var skip = 0;
        
        for (index,character) in colony.enumerated(){
            var cell:String? = nil; //False = dead;
            var cellCount = 0;
            
            if (skip > 0){
                skip-=1;
                continue;
            }
            if character == "$"{
                yPos += 1;
                xPos = 1;
                continue;
            }else if character == "!"{
                let width = base.colony.Cells.max(by: { cell1, cell2 in
                    return cell1.X <= cell2.X;
                })
                let height = base.colony.Cells.max(by: { cell1, cell2 in
                    return cell1.Y <= cell2.Y;
                })
                base.size = max(height?.Y ?? 0,width?.X ?? 0);
                return base;
            }
            
            if numberFormatter.number(from: String(character)) != nil{
                var groupLength:Int = 1;
                for i in 1...5{
                    let sIndex = colony.index(colony.startIndex, offsetBy: index + i)
                    if numberFormatter.number(from: String(colony[sIndex])) != nil{
                        groupLength += 1;
                    }else{
                        break;
                    }
                }
                let sIndex = colony.index(colony.startIndex, offsetBy: index)
                let eIndex = colony.index(colony.startIndex, offsetBy: index + groupLength - 1)
                let number = numberFormatter.number(from: String(colony[sIndex...eIndex]))
                
                
                cell = String(colony[colony.index(eIndex, offsetBy: 1)]);
                cellCount = Int(number!);
                
                skip = groupLength;
            }
            
            if character == "o" || character == "b"{
                cellCount = 1;
            }
            
            let cellType = cell ?? "";
            
            if character == "o" || character == "b" || cellType != ""{
                if character == "o" || cellType == "o"{
                    for x in 1...cellCount{
                        xPos += 1;
                        base.colony.setCellAlive(X: xPos, Y: yPos)
                    }
                }else if character == "b" || cellType=="b"{
                    xPos += cellCount
                }else if cellType == "$"{
                    yPos += cellCount;
                    xPos = 1;
                }
            }
        }
        return nil;
    }
    
    init(size: Int){
        self.size = size
    }
    
    convenience init (_ wrapping: Bool){
        self.init(size:1);
        self.wrapping = wrapping;
    }
    
    convenience init (){
        self.init(size:1);
    }
    
    func changeCell(_ cell: Cell){
    }
    
    func setCellAlive(X: Int, Y: Int){ Cells.insert(Cell(X, Y, size: size,wrapping)) }
    
    func setCellDead(X: Int, Y: Int){ Cells.remove(Cell(X, Y, size: size,wrapping)) }
    
    func toggleCellAlive(X:Int,Y:Int){
        if isCellAlive(X:X,Y:Y){
            setCellDead(X:X,Y:Y);
        }else{
            setCellAlive(X: X, Y: Y);
        }
        
        //print("Changing cell state: \(X),\(Y)");
    }
    
    func isCellAlive(X: Int, Y: Int)-> Bool{
        return Cells.contains(Cell(X, Y, size: size,wrapping))
    }
    
    func resetColony(){ Cells.removeAll(); }
    
    var description: String{
        let xWidth = Cells.max(by:{ (a,b) in
            if a.X < b.X{
                return true;
            }
            return false;
        })?.X
        let yHeight = Cells.max(by:{ (a,b) in
            if a.Y < b.Y{
                return true;
            }
            return false;
        })?.Y
        
        guard let height = yHeight, let width = xWidth else{
            return "error";
        }
        
        var text = "";
        for x in 0...abs(height){ //Reverses description.
            for y in 0...abs(width){
                text += (self.isCellAlive(X: y, Y: x) ? "*" : "-");
            }
            text += "\n";
        }
        
        return text;
    }
    
    //Gets # of cells surrounding given coord.
    private func crowd(X:Int, Y:Int)->Int{
        var Alive = 0;
        Alive += isCellAlive(X: X - 1,Y:Y + 1) ? 1:0;
        Alive += isCellAlive(X: X,Y:Y + 1) ? 1:0;
        Alive += isCellAlive(X: X + 1,Y:Y + 1) ? 1:0;
        Alive += isCellAlive(X: X - 1,Y:Y) ? 1:0;
        Alive += isCellAlive(X: X + 1,Y:Y) ? 1:0;
        Alive += isCellAlive(X: X - 1,Y:Y - 1) ? 1:0;
        Alive += isCellAlive(X: X,Y:Y - 1) ? 1:0;
        Alive += isCellAlive(X: X + 1,Y:Y - 1) ? 1:0;
        return Alive;
    }
    
    func willLive(C:Cell)->Bool{
        let isAlive = isCellAlive(X: C.X,Y:C.Y);
        let Surround = crowd(X: C.X,Y:C.Y)
        if (isAlive){
            if Surround == 2 || Surround == 3{
                return true;
            }
        }else{
            if Surround == 3{
                return true;
            }
        }
        return false;
    }
    
    func evolve(){
        var queueList = Set<Cell>();
        
        Cells.forEach({
            for x in $0.X - 1 ... $0.X + 1{
                for y in $0.Y - 1 ... $0.Y + 1{
                    queueList.insert(Cell(x, y, size: size,wrapping));
                }
            }
        })
        
        Cells = Set<Cell>(queueList.filter(willLive))
    }
}
