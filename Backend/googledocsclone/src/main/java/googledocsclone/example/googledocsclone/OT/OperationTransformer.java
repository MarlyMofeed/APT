package googledocsclone.example.googledocsclone.OT;
import java.util.ArrayList;
import java.util.List;

public class OperationTransformer {

    public static void transformInsert(InsertOperation op1, InsertOperation op2)
    {
        //TODO: law el row full w h insert in it ha7tag anazel ay haga b3d el insert lel next row f kolo
        if (op1.getRow() == op2.getRow() && op1.getCol() > op2.getCol())
        {
            op1.setCol(op1.getCol() + 1);
        }
        else if (op1.getRow() == op2.getRow() && op1.getCol() == op2.getCol())
        {
            op1.setCol(op1.getCol() + 1);
        }
        else if (op1.getRow() == op2.getRow() && op1.getCol() < op2.getCol())
        {
            op1.setCol(op1.getCol());
        }
    }

    public static void transformDelete(DeleteOperation op1, DeleteOperation op2)
    {
        if (op1.getRow() == op2.getRow() && op1.getCol() > op2.getCol())
        {
            op1.setCol(op1.getCol() - 1);
        }
        else if (op1.getRow() == op2.getRow() && op1.getCol() == op2.getCol())
        {
            op1.setCol(op1.getCol() - 1);
        }
        else if (op1.getRow() == op2.getRow() && op1.getCol() < op2.getCol())
        {
            op1.setCol(op1.getCol());
        }
    }

    public static void transformInsertDelete(InsertOperation op1, DeleteOperation op2)
    {
        if (op1.getRow() == op2.getRow() && op1.getCol() > op2.getCol())
        {
            op1.setCol(op1.getCol() - 1);
        }
        else if (op1.getRow() == op2.getRow() && op1.getCol() == op2.getCol())
        {
            op1.setCol(op1.getCol());
        }
        else if (op1.getRow() == op2.getRow() && op1.getCol() < op2.getCol())
        {
            op1.setCol(op1.getCol());
        }
    }

    public static void transformDeleteInsert(DeleteOperation op1, InsertOperation op2)
    {
        if (op1.getRow() == op2.getRow() && op1.getCol() > op2.getCol())
        {
            op1.setCol(op1.getCol() + 1);
        }
        else if (op1.getRow() == op2.getRow() && op1.getCol() == op2.getCol())
        {
            op1.setCol(op1.getCol() + 1);
        }
        else if (op1.getRow() == op2.getRow() && op1.getCol() < op2.getCol())
        {
            op1.setCol(op1.getCol());
        }
    }

    public static void transformInsert(List<InsertOperation> ops1, List<InsertOperation> ops2)
    {
        for (InsertOperation op1 : ops1)
        {
            for (InsertOperation op2 : ops2)
            {
                transformInsert(op1, op2);
            }
        }
    }

    public static void transformDelete(List<DeleteOperation> ops1, List<DeleteOperation> ops2)
    {
        for (DeleteOperation op1 : ops1)
        {
            for (DeleteOperation op2 : ops2)
            {
                transformDelete(op1, op2);
            }
        }
    }

    public static void transformInsertDelete(List<InsertOperation> ops1, List<DeleteOperation> ops2)
    {
        for (InsertOperation op1 : ops1)
        {
            for (DeleteOperation op2 : ops2)
            {
                transformInsertDelete(op1, op2);
            }
        }
    }

    public static void transformDeleteInsert(List<DeleteOperation> ops1, List<InsertOperation> ops2)
    {
        for (DeleteOperation op1 : ops1)
        {
            for (InsertOperation op2 : ops2)
            {
                transformDeleteInsert(op1, op2);
            }
        }
    }
}
